pushd .; cd ../../test; source ./compile.sh ; popd;

cp ../../test/tt flash.in; make sim_vcd

