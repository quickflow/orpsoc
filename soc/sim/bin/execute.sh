pushd .; cd ../../test; ./compile.sh ; popd;

cp ../../test/tt flash.in; make sim
