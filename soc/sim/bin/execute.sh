pushd .; cd ../../../tools/or1k-linux/test; ./compile.sh ; popd;

cp ../../../tools/or1k-linux/test/tt flash.in; make sim
