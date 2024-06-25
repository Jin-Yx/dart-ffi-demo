import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as path;
// add ffi ^2.1.2 dependencies to pubspec.yaml
import 'package:ffi/ffi.dart';

void primitives() {
  String libPath;
  if (Platform.isLinux) {
    libPath = path.join(Directory.current.path, 'code/c/int-int/libprimitives.so');
  } else if (Platform.isMacOS) {
    libPath = path.join(Directory.current.path, 'code/c/int-int/libprimitives.dylib');
  } else if (Platform.isWindows) {
    libPath = path.join(Directory.current.path, 'code', 'c', 'int-int', 'primtives.dll');
  } else {
    throw OSError("unsupported platform: ${Platform.operatingSystem}");
  }

  var dynamicFile = File(libPath);
  if (!dynamicFile.existsSync()) {
    print("$libPath 不存在，请先编译动态库");
    return;
  }
  final dylib = DynamicLibrary.open(libPath);

  /// ----------------------------------------------------------
  var sumFunc = dylib
      .lookup<NativeFunction<Int32 Function(Int32, Int32)>>("sum")
      .asFunction<int Function(int, int)>();
  sumFunc = dylib.lookupFunction<Int32 Function(Int32, Int32), int Function(int, int)>("sum");
  print('3 + 5 = ${sumFunc(3, 5)}');

  int Function(Pointer<Int32>, int) subFunc = dylib
      .lookup<NativeFunction<Int32 Function(Pointer<Int32>, Int32)>>("subtract")
      .asFunction();
  subFunc = dylib.lookupFunction<Int32 Function(Pointer<Int32>, Int32), int Function(Pointer<Int32>, int)>("subtract");
  var pointer = calloc<Int32>();
  pointer.value = 3;
  print('3 - 5 = ${subFunc(pointer, 5)}');
  calloc.free(pointer);

  Pointer<Int32> Function(int, int) multiFunc = dylib
      .lookup<NativeFunction<Pointer<Int32> Function(Int32, Int32)>>("multiply")
      .asFunction();
  multiFunc = dylib.lookupFunction<Pointer<Int32> Function(Int32, Int32), Pointer<Int32> Function(int, int)>('multiply');
  Pointer<Int32> multiPointer = multiFunc(3, 5);
  print('3 * 5 = ${multiPointer.value}');

  void Function(Pointer<Int32>) freeFunc = dylib
      .lookup<NativeFunction<Void Function(Pointer<Int32>)>>("free_pointer")
      .asFunction();
  freeFunc = dylib.lookupFunction<Void Function(Pointer<Int32>), void Function(Pointer<Int32>)>('free_pointer');
  freeFunc(multiPointer);
}
