import 'package:flutter/material.dart';
import '../services/hashtag_service.dart';

class HashtagText extends StatelessWidget {
  const HashtagText(
    this.text, {
    super.key,
    this.style,
    this.onHashtagTap,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final Function(String hashtag)? onHashtagTap;
  final int? maxLines;
  final TextOverflow? overflow;

  List<TextSpan> _buildSpans(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'#(\w+)');
    var lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before hashtag
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(text: text.substring(lastEnd, match.start), style: style),
        );
      }

      // Add hashtag as styled link
      final hashtag = match.group(0)!; // includes the #
      spans.add(
        TextSpan(
          text: hashtag,
          style: (style ?? const TextStyle()).copyWith(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // Extract hashtag without the #
              final tag = match.group(1)!;
              onHashtagTap?.call(tag);
            },
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }

    return spans.isEmpty ? [TextSpan(text: text, style: style)] : spans;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(children: _buildSpans(context)),
    );
  }
}
