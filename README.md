## 一、dart 调 c

### [1、无参无返回值](./lib/c/void-void.dart)

~~~shell
# 编译成动态库以供调用
cd code/c/void-void
cmake CMakeLists.txt
make
# 运行 dart 程序
cd ../../..
# 可省，新加入依赖时执行
dart pub get
dart run lib/ffi_demo.dart
~~~

### [2、参数返回值为整形或指针](./lib/c/int-int.dart) 

~~~shell
# 编译成动态库以供调用
cd code/c/int-int
cmake CMakeLists.txt
make
# 运行 dart 程序
cd ../../..
# 可省，新加入依赖时执行
dart pub get
dart run lib/ffi_demo.dart
~~~

### [3、参数返回值为字符串或结构体](./lib/c/str-struct.dart)

~~~shell
# 编译成动态库以供调用
cd code/c/str-struct
cmake CMakeLists.txt
make
# 运行 dart 程序
cd ../../..
# 可省，新加入依赖时执行
dart pub get
dart run lib/ffi_demo.dart
~~~


## 二、dart 调 java/kotlin

