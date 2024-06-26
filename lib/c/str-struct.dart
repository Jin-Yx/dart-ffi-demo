import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

// Example of handling a simple C struct
final class Coordinate extends Struct {
  @Double()
  external double latitude;

  @Double()
  external double longitude;
}

// Example of a complex struct (contains a string and a nested struct)
final class Place extends Struct {
  external Pointer<Utf8> name;

  external Coordinate coordinate;
}

typedef DistanceNative = Double Function(Coordinate, Coordinate);
typedef Distance = double Function(Coordinate, Coordinate);

void strStruct() {
  String libPath;
  if (Platform.isLinux) {
    libPath = path.join(Directory.current.path, 'code/c/str-struct/libstructs.so');
  } else if (Platform.isMacOS) {
    libPath = path.join(Directory.current.path, 'code/c/str-struct/libstructs.dylib');
  } else if (Platform.isWindows) {
    libPath = path.join(Directory.current.path, 'code', 'c', 'str-struct', 'structs.dll');
  } else {
    throw OSError("unsupported platform: ${Platform.operatingSystem}");
  }
  var dynamicFile = File(libPath);
  if (!dynamicFile.existsSync()) {
    print('$libPath 不存在，请先编译动态库');
    return;
  }

  final dylib = DynamicLibrary.open(libPath);

  var helloWorld = dylib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>("hello_world");
  print(helloWorld().toDartString());

  var reverseFunc = dylib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>("reverse");
  final str = "Hello World".toNativeUtf8();
  final reversedStr = reverseFunc(str);
  print(reversedStr.toDartString());
  calloc.free(str);

  var freeFunc = dylib.lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>("free_string");
  freeFunc(reversedStr);

  final createCoordinate = dylib.lookupFunction<Coordinate Function(Double, Double), Coordinate Function(double, double)>("create_coordinate");
  final coordinate = createCoordinate(3.5, 4.6);
  print('Coordinate is lat ${coordinate.latitude}, long ${coordinate.longitude}');

  final myHomeUtf8 = 'My Home'.toNativeUtf8();
  final createPlace = dylib.lookupFunction<Place Function(Pointer<Utf8>, Double, Double), Place Function(Pointer<Utf8>, double, double)>("create_place");
  final place = createPlace(myHomeUtf8, 42.0, 24.0);
  print('Place is ${place.name.toDartString()}, lat ${place.coordinate.latitude}, long ${place.coordinate.longitude}');
  calloc.free(myHomeUtf8);

  final distance = dylib.lookupFunction<DistanceNative, Distance>('distance');
  final dist = distance(createCoordinate(2.0, 2.0), createCoordinate(5.0, 6.0));
  print("distance between (2,2) and (5,6) = $dist");
}
