import 'dart:io';

import 'package:flutter/material.dart';

/// Loads a file-backed image from a local path.
///
/// Native platforms read the file through `dart:io`. This is the default
/// implementation; web builds get [image_file_loader_web.dart] instead through
/// a conditional import, because `dart:io` is unavailable on the web.
ImageProvider? loadFileImage(String path) => FileImage(File(path));
