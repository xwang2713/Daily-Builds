#cd build

/usr/local/bin/cmake ../$1 -DGENERATE_COVERAGE_INFO=0 -DUSE_LIBXSLT=ON -DXALAN_LIBRARIES= -DMYSQL_LIBRARIES=/usr/lib64/mysql/libmysqlclient.so
 -DMYSQL_INCLUDE_DIR=/usr/include/mysql -DMAKE_MYSQLEMBED=1 

#/usr/local/bin/cmake ../$1 -DUSE_LIBXSLT=ON -DXALAN_LIBRARIES= -DCLIENTTOOLS_ONLY=ON
#make
#make package
