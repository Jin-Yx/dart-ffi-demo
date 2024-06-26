&emsp;c 示例代码分了 3 个部分，需要进入对应目录下执行如下命令编译动态库

~~~shell
# 例如 cd code/c/int-int
cd code/c/xxx
cmake CMakeLists.txt
make
~~~

&emsp;在项目根目录下运行如下命令，运行 dart 调用 c 函数

~~~shell
# 可省，新加入依赖时执行
dart pub get
dart run lib/ffi_demo.dart
~~~

<hr/>

## 一、加载动态库

&emsp;&emsp;dart 调用 c 函数，需要将 c 先编成动态库，然后通过 `dart:ffi` 加载动态库，再通过 `dart:ffi` 调用 c 函数。

~~~dart
import 'dart:io';

import 'package:path/path.dart' as path;
import 'dart:ffi';

DynamicLibrary _dylib;

void openDyLib() {
  String libPath;
  if (Platform.isLinux) {
    libPath = '/{dynamic lib dir}/libXXX.so';
  } else if (Platform.isMacOS) {
    libPath = '/{dynamic lib dir}/libXXX.dylib';
  } else if (Platform.isWindows) {
    libPath = path.join(Directory.current.path, '{dynamic}', '{lib}', '{dir}', 'XXX.dll');
  }
  _dylib = DynamicLibrary.open(libPath);
}
~~~

## 二、调用 c 函数

### 1、无参无返回值函数调用

~~~c
void hello_world() {
    printf("Hello World: 无参无返回值\n");
}
~~~

&emsp;&emsp;上面是 c 函数，下面是 dart 调用，lookup 和 lookupFunction 等效

~~~dart
void callVoid() {
  var helloFunc = _dylib
      .lookup<NativeFunction<Void Function()>>('hello_world')
      .asFunction<void Function()>();
  // helloFunc = _dylib.lookupFunction<Void Function(), void Function()>('hello_world');
  helloFunc();
}
~~~

- Void Function(): c 函数签名
- void Function(): dart 函数签名，即 helloFunc 变量的类型
- hello_world: c 函数名称

&emsp;&emsp;dart 中也有类似 c 的 `typedef` 语法，用于给类型取别名；上面的 dart 代码可以写成如下方式

~~~dart
typedef NativeHelloWorld = Void Function();
typedef HelloWorld = void Function();

void callVoid() {
  var helloFunc = _dylib.lookupFunction<NativeHelloWorld, HelloWorld>('hello_world');
  helloFunc();
}
~~~

### 2、参数、返回值为 int 或 int 指针

~~~c
int sum(int a, int b) {
    return a + b;
}

int subtract(int *a, int b) {
    return *a - b;
}

int *multiply(int a, int b) {
    int *mult = (int *)malloc(sizeof(int));
    *mult = a * b;
    return mult;
}

void free_pointer(int *int_pointer) {
    free(int_pointer);
}
~~~

- [sum](#sum): 接收两个 int 参数，返回 int 类型的两数之和
- [subtract](#subtract): 接收一个 int 指针和一个 int 参数，返回 int 类型的两数之差
- [multiply](#multiply): 接收两个 int 参数，返回一个 int 指针，该指针指向一个 int 类型的两数之积
- [free_pointer](#free_pointer): 接收一个 int 指针参数，返回 void；用于释放 multiply 函数中申请的内存

<a id="sum"></a>

#### **2.1、sum**

~~~dart
var sumFunc = _dylib
  .lookup<NativeFunction<Int32 Function(Int32, Int32)>>("sum")
  .asFunction<int Function(int, int)>();
// sumFunc = _dylib.lookupFunction<Int32 Function(Int32, Int32), int Function(int, int)>("sum");
print('3 + 5 = ${sumFunc(3, 5)}');
~~~

- Int32 Function(Int32, Int32): c sum 函数签名；第一个参数 int，第二个参数 int，返回 int 值
- int Function(int, int): dart 函数签名，即 sumFunc 变量的类型
- sum: c 函数名称

<a id="subtract"></a>

#### **2.2、subtract**

~~~dart
var subFunc = _dylib
  .lookup<NativeFunction<Int32 Function(Pointer<Int32>, Int32)>>("subtract")
  .asFunction<int Function(Pointer<Int32>, int)>();
// subFunc = _dylib.lookupFunction<Int32 Function(Pointer<Int32>, Int32), int Function(Pointer<Int32>, int)>("subtract");
var pointer = calloc<Int32>();
pointer.value = 3;
print('3 - 5 = ${subFunc(pointer, 5)}');
calloc.free(pointer);
~~~

- Int32 Function(Pointer<Int32>, Int32): c subtract 函数签名；第一个参数 int 指针，第二个参数 int，返回 int 值
- int Function(Pointer<Int32>, int): dart 函数签名，即 subFunc 变量的类型
- subtract: c 函数名称

&emsp;&emsp;因为需要传入 int 指针，所以通过 `package:ffi/ffi.dart` 中的 `calloc` 申请内存，返回指针地址；使用完成后调用 `calloc.free` 释放内存。要使用该包需要添加如下依赖

~~~yaml
dependencies:
  ffi: ^2.1.2
~~~

<a id="multiply"></a>

#### **2.3、multiply**

~~~dart
var multiFunc = _dylib
  .lookup<NativeFunction<Pointer<Int32> Function(Int32, Int32)>>("multiply")
  .asFunction<Pointer<Int32> Function(int, int)>();
// multiFunc = _dylib.lookupFunction<Pointer<Int32> Function(Int32, Int32), Pointer<Int32> Function(int, int)>('multiply');
Pointer<Int32> multiPointer = multiFunc(3, 5);
print('3 * 5 = ${multiPointer.value}');
~~~

- Pointer<Int32> Function(Int32, Int32): c multiply 函数签名；第一个参数 int 指针，第二个参数 int，返回 int 指针
- Pointer<Int32> Function(int, int): dart 函数签名，即 multiFunc 变量的类型
- multiply: c 函数名称

<a id="free_pointer"></a>

#### **2.4、free_pointer**

~~~dart
var freeFunc = _dylib
  .lookup<NativeFunction<Void Function(Pointer<Int32>)>>("free_pointer")
  .asFunction<void Function(Pointer<Int32>)>();
// freeFunc = _dylib.lookupFunction<Void Function(Pointer<Int32>), void Function(Pointer<Int32>)>('free_pointer');
freeFunc(multiPointer);
~~~

- Void Function(Pointer<Int32>): c subtract 函数签名；接收 int 指针参数，无返回
- void Function(Pointer<Int32>): dart 函数签名，即 freeFunc 变量的类型
- free_pointer: c 函数名称


### 3、参数、返回值为 字符串 或 结构体

#### **3.1、无参，返回字符串常量**

~~~c
char *hello_world() {
    return "Hello World";
}
~~~

~~~dart
var helloFunc = _dylib
  .lookup<NativeFunction<Pointer<Utf8> Function()>>("hello_world")
  .asFunction<Pointer<Utf8> Function()>();
// helloFunc = _dylib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('hello_world');
print(helloFunc().toDartString());
~~~

&emsp;&emsp;关于 `Pointer<Utf8>`，dart 介绍如下，Utf8 本身没有任何功能，只能通过 `Pointer<Utf8>` 来表示整个数组，等价于 c 中的字符指针(const char*)。

&emsp;&emsp;`Pointer<Utf8>` 需要通过 `toDartString()` 转换为 Dart 字符串。否则打印出来的是 `Pointer: address=0x79730af1e0a9`

~~~dart
/// The contents of a native zero-terminated array of UTF-8 code units.
///
/// The Utf8 type itself has no functionality, it's only intended to be used
/// through a `Pointer<Utf8>` representing the entire array. This pointer is
/// the equivalent of a char pointer (`const char*`) in C code.
final class Utf8 extends Opaque {}
~~~

#### **3.2、参数返回值为字符指针**

~~~c
char *reverse(char *str) {
    int lenght = strlen(str);
    char *reversed_str = (char *)malloc((length + 1) * sizeof(char));
    for (int i = 0; i < length; i++) {
        reversed_str[length - i - 1] = str[i];
    }
    reversed_str[length] = '\0';
    return reversed_str;
}

void free_string(char *str) {
    free(str);
}
~~~

~~~dart
var reverseFunc = _dylib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>("reverse")
    .asFunction<Pointer<Utf8> Function(Pointer<Utf8>)>();
// reverseFunc = _dylib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>("reverse");
final str = "Hello World".toNativeUtf8();
final reversedStr = reverseFunc(str);
print(reversedStr.toDartString());
calloc.free(str);

var freeFunc = _dylib.lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>("free_string");
freeFunc(reversedStr);
~~~

#### **3.3、参数或返回值为结构体**

~~~c
struct Coordinate {
    double latitude;
    double longitude;
};

struct Place {
    char *name;
    struct Coordinate coordinate;
};
~~~

&emsp;&emsp;c 中定义了两个结构体，`Coordinate` 和 `Place`，其在 dart 中的实现如下：

~~~dart
final class Coordinate extends Struct {
  @Double()
  external double latitude;
  @Double()
  external double longitude;
}

final class Place extends Struct {
  external Pointer<Utf8> name;
  external Coordinate coordinate;
}
~~~

&emsp;&emsp;传入两个 double 参数，创建一个 `Coordinate` 结构体，并返回。

~~~c
struct Coordinate create_coordinate(double latitude, double longitude){
    struct Coordinate coordinate;
    coordinate.latitude = latitude;
    coordinate.longitude = longitude;
    return coordinate;
}
~~~

~~~dart
final createFunc = _dylib.lookupFunction<Coordinate Function(Double, Double), Coordinate Function(double, double)>("create_coordinate");
final coordinate = createFunc(3.5, 4.6);
print('Coordinate is lat ${coordinate.latitude}, long ${coordinate.longitude}');
~~~

&emsp;&emsp;传入 字符指针、double、double 三个参数，创建一个 `Place` 结构体，并返回。

~~~c
struct Place create_place(char *name, double latitude, double longitude){
    struct Place place;
    place.name = name;
    place.coordinate = create_coordinate(latitude, longitude);
    return place;
}
~~~

~~~dart
final placeFunc = _dylib.lookupFunction<Place Function(Pointer<Utf8>, Double, Double), Place Function(Pointer<Utf8>, double, double)>("create_place");
Pointer<Utf8> name = "Beijing".toNativeUtf8();
final place = placeFunc(name, 42.0, 24.0);
print('Place is ${place.name.toDartString()}, lat ${place.coordinate.latitude}, long ${place.coordinate.longitude}');
// 如果是释放完 name 再调用上面打印 name 会报错
calloc.free(name);
~~~
