import 'dart:async';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
// import 'package:image_fade/image_fade.dart';
import 'package:inspireui/inspireui.dart' show Skeleton;
import 'package:transparent_image/transparent_image.dart';

import '../config.dart' show kAdvanceConfig;
import '../constants.dart' show kCacheImageWidth, kEmptyColor, kIsWeb;
import '../tools.dart';

// ignore: camel_case_types
enum kSize { small, medium, large }

class ImageResize extends StatelessWidget {
  final String? url;
  final kSize? size;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final String? tag;
  final double offset;
  final bool isResize;
  final bool hidePlaceHolder;
  final bool forceWhiteBackground;
  final String kImageProxy;

  const ImageResize({
    Key? key,
    this.url,
    this.size,
    this.width,
    this.height,
    this.fit,
    this.tag,
    this.isResize = false,
    this.hidePlaceHolder = false,
    this.offset = 0.0,
    this.forceWhiteBackground = false,
    this.kImageProxy = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var width = this.width;
    if (height == null && width == null) {
      width = 200;
    }
    var ratioImage = kAdvanceConfig.ratioProductImage;

    if (url?.isEmpty ?? true) {
      return FutureBuilder<bool>(
        future: Future.delayed(const Duration(seconds: 10), () => false),
        initialData: true,
        builder: (context, snapshot) {
          final showSkeleton = snapshot.data!;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: showSkeleton
                ? Skeleton(
                    width: width!,
                    height: height ?? width * ratioImage,
                  )
                : SizedBox(
                    width: width,
                    height: height ?? width! * ratioImage,
                    child: const Icon(Icons.error_outline),
                  ),
          );
        },
      );
    }

    if (kIsWeb) {
      /// temporary fix on CavansKit https://github.com/flutter/flutter/issues/49725
      var imageURL = isResize ? ImageTools.formatImage(url, size) : url;

      var imageProxy = '$kImageProxy${width}x,q50/';
      if (kImageProxy.isEmpty) {
        /// this image proxy is use for demo purpose, please make your own one
        imageProxy = 'https://cors.mstore.io/';
      }

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: width! * ratioImage),
        child: FadeInImage.memoryNetwork(
          image: '$imageProxy$imageURL',
          fit: fit,
          width: width,
          height: height,
          placeholder: kTransparentImage,
        ),
      );
    }

    final cacheWidth =
        (width != null && width > 0) ? (width * 2.5).toInt() : kCacheImageWidth;

    final image = ExtendedImage.network(
      isResize ? ImageTools.formatImage(url, size)! : url!,
      width: width,
      height: height,
      fit: fit,
      cache: true,
      clearMemoryCacheWhenDispose: true,
      cacheWidth: cacheWidth,
      enableLoadState: false,
      alignment: Alignment(
        (offset >= -1 && offset <= 1)
            ? offset
            : (offset > 0)
                ? 1.0
                : -1.0,
        0.0,
      ),
      loadStateChanged: (ExtendedImageState state) {
        Widget? widget;
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            widget = hidePlaceHolder
                ? const SizedBox()
                : Skeleton(
                    width: width ?? 100,
                    height: width != null
                        ? width * (ratioImage * 1.0)
                        : 100.0 * ratioImage,
                  );
            break;
          case LoadState.completed:
            return state.completedWidget;
          // return ImageFade(
          //   image: state.imageProvider,
          //   width: width,
          //   height: height,
          //   fit: fit ?? BoxFit.scaleDown,
          //   alignment: Alignment(
          //     (offset >= -1 && offset <= 1)
          //         ? offset
          //         : (offset > 0)
          //             ? 1.0
          //             : -1.0,
          //     0.0,
          //   ),
          //   duration: const Duration(milliseconds: 250),
          // );
          case LoadState.failed:
            widget = Container(
              width: width,
              height: height ?? width! * ratioImage,
              color: const Color(kEmptyColor),
            );
            break;
        }
        return widget;
      },
    );

    if (forceWhiteBackground && url!.toLowerCase().endsWith('.png')) {
      return Container(
        color: Colors.white,
        child: image,
      );
    }

    return image;
  }
}
