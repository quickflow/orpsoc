# golden_gemm_dp.py
N = 16

def saturate(value, bits):
    if bits == 16:
        return max(-32768, min(32767, value))
    elif bits == 8:
        return max(-128, min(127, value))
    else:
        raise ValueError("bits must be 8 or 16")

def tosigned(val, bits):
    mask = (1<<bits)-1
    v = val & mask
    if v & (1<<(bits-1)):
        v -= (1<<bits)
    return v

def leaky_relu(x, alpha_q1_7):
    alpha = tosigned(alpha_q1_7, 8)
    return x if x>=0 else (x*alpha)>>7

def quant_q1616(x, scale_q1616, zero_point):
    return ((x*scale_q1616 + (1<<15))>>16) + zero_point

def gemm_ref(A, B, mode_dw16=True, activation_en=False, quant_en=False,
             activation_type_relu=True, signed_inputs=True,
             leaky_alpha_q1_7=0x10, quant_scale_q1616=(1<<16), quant_zero=0):
    C = [[0 for _ in range(N)] for _ in range(N)]
    in_bits = 16 if mode_dw16 else 8
    for i in range(N):
        for j in range(N):
            acc = 0
            for k in range(N):
                a = A[i][k]
                b = B[k][j]
                if signed_inputs:
                    a = tosigned(a, in_bits)
                    b = tosigned(b, in_bits)
                else:
                    a &= (1<<in_bits)-1
                    b &= (1<<in_bits)-1
                acc += a * b
            x = acc
            if activation_en:
                if activation_type_relu:
                    x = max(0, x)
                else:
                    x = leaky_relu(x, leaky_alpha_q1_7)
            if quant_en:
                x = quant_q1616(x, quant_scale_q1616, quant_zero)
            C[i][j] = saturate(x, in_bits)
    return C

def signed_decimal_to_hex(num: int, bits: int = 32) -> str:
    """
    Convert a signed decimal integer to hexadecimal using two's complement.
    
    Args:
        num (int): The signed decimal integer.
        bits (int): Bit width (default 32 bits).
    
    Returns:
        str: Hexadecimal string (without '0x' prefix).
    """
    if not isinstance(num, int):
        raise TypeError("Input must be an integer.")
    if bits <= 0:
        raise ValueError("Bit width must be positive.")
    
    # Range check for the given bit width
    min_val = -(1 << (bits - 1))
    max_val = (1 << (bits - 1)) - 1
    if num < min_val or num > max_val:
        raise OverflowError(f"Number out of range for {bits}-bit signed integer.")
    
    # Handle two's complement for negative numbers
    if num < 0:
        num = (1 << bits) + num  # Convert to unsigned equivalent
    
    return format(num, f'0{bits // 4}X')  # Uppercase hex, zero-padded


if __name__ == "__main__":
    def val(r,c): return r + 2*c - 3
    A = [[val(r,t) for t in range(N)] for r in range(N)]
    B = [[val(t,c) for c in range(N)] for t in range(N)]
    C = gemm_ref(A,B,True,False,False)
    
    print("Test1 16-bit no act/quant A[0][0]:", A[0][0], "B[0][0]:", B[0][0], "C[0][0]:", C[0][0])
    print("Matrix A:")
    for i in range(N):
        for j in range(N):
            print(signed_decimal_to_hex(A[i][j], 16), " ", end='')
        print()

    print("Matrix B:")
    for i in range(N):
        for j in range(N):
            print(signed_decimal_to_hex(B[i][j], 16), " ", end='')
        print()

    print("Matrix C:")
    for i in range(N):
        for j in range(N):
            print(signed_decimal_to_hex(C[i][j], 16), " ", end='')
        print()

    print("Test2 16-bit ReLU C[0][0]:", gemm_ref(A,B,True,True,False)[0][0])
    print("Test3 8-bit ReLU+quant C[0][0]:", gemm_ref(A,B,False,True,True,True,0x10,int(0.125*(1<<16)),0)[0][0])
    print("Test4 8-bit Leaky+quant C[0][0]:", gemm_ref(A,B,False,True,True,False,0x10,int(0.5*(1<<16)),0)[0][0])
