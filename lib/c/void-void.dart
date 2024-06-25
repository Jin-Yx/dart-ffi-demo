import 'dart:io';

import 'package:path/path.dart' as path;
import 'dart:ffi';

void helloWorld() {
  String libPath;
  // Directory.current.path 表示 dart 当前运行时所在目录
  if (Platform.isLinux) {
    libPath = path.join(Directory.current.path, 'code/c/void-void/libhello.so');
  } else if (Platform.isMacOS) {
    libPath = path.join(Directory.current.path, 'code/c/void-void/libhello.dylib');
  } else if (Platform.isWindows) {
    libPath = path.join(Directory.current.path, 'code', 'c', 'void-void', 'hello.dll');
  } else {
    throw OSError("unsupported platform: ${Platform.operatingSystem}");
  }
  var dynamicFile = File(libPath);
  if (dynamicFile.existsSync()) {
    final dylib = DynamicLibrary.open(libPath);
    var helloFunc = dylib
        .lookup<NativeFunction<Void Function()>>('hello_world')
        .asFunction<void Function()>();
    // helloFunc = dylib.lookupFunction<Void Function(), void Function()>('hello_world');
    helloFunc();
  } else {
    print("$libPath 不存在，请先编译动态库");
  }
}