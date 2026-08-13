// imagekit_url.dart — deriving a thumbnail URL we know renders.
//
// ── WHY THE PHOTOS WERE NOT SHOWING ──────────────────────────────────
//
// Every product had a photo. The product detail page showed it. The
// catalog list showed a grey box icon for all fifty, and so did the
// editor's photo strip.
//
// The difference between those two places was one field. The detail
// page's main image renders `media.url`. Everywhere else rendered
// `media.thumbnailUrl ?? media.url` — and thumbnailUrl is not something
// we built, it is a field copied verbatim out of ImageKit's upload
// response:
//
//   url        https://ik.imagekit.io/somtech/kola/.../product-50-….jpg
//   thumbnail  https://ik.imagekit.io/somtech/tr:n-ik_ml_thumbnail/kola/…
//
// `n-ik_ml_thumbnail` is a NAMED transformation — ImageKit's ML smart-crop
// preset. It is returned in the upload response on every account, but it
// only RESOLVES on accounts where that add-on is enabled. Everywhere else
// the URL is a 4xx, the <img> fails, and the browser shows nothing. No
// console error we were watching for, no failed request we logged: just a
// blank box that looks exactly like "this product has no photo".
//
// I stored that field because the API returned it. Returning a value and
// that value working are different claims, and I only checked the first.
//
// ── THE FIX: DERIVE, DO NOT STORE ────────────────────────────────────
//
// ImageKit transformations are path segments, so a thumbnail is a pure
// function of the original URL:
//
//   .../somtech/kola/workspaces/12/x.jpg
//   .../somtech/tr:w-84,h-84,c-maintain_ratio,fo-auto/kola/workspaces/12/x.jpg
//
// w/h/c/fo are core transformations available on every plan, unlike the
// named ML preset.
//
// Deriving at RENDER time rather than fixing the stored column also
// repairs the fifty rows already in the database without a data
// migration, and means a future change of thumbnail size is a code change
// rather than a backfill.
//
// Sizes are asked for at 2× the CSS box so they stay sharp on the phone
// screens most of these owners are using.

abstract class ImageKitUrl {
  /// Where our ImageKit account lives. Anything not under this host is
  /// returned untouched — see [thumb].
  static const _marker = 'ik.imagekit.io/';

  /// A resized version of [url], or [url] itself when it is not an
  /// ImageKit URL.
  ///
  /// Returning the original unchanged is deliberate. Media can arrive
  /// from places other than our own uploader — a CSV import that failed
  /// to copy, an older row, a future provider — and a full-size photo
  /// that renders is strictly better than a transformed URL that 404s.
  /// The whole reason this file exists is a thumbnail that did not load.
  static String thumb(String url, {int size = 84}) {
    final at = url.indexOf(_marker);
    if (at < 0) return url;

    // .../ik.imagekit.io/<imagekitId>/<path>
    final afterHost = at + _marker.length;
    final slash = url.indexOf('/', afterHost);
    if (slash < 0) return url;

    // Already carries a transformation — leave it alone rather than
    // stacking a second `tr:` segment, which ImageKit reads as a chained
    // transformation and is not what any caller here means.
    if (url.startsWith('tr:', slash + 1)) return url;

    final head = url.substring(0, slash + 1);
    final tail = url.substring(slash + 1);
    return '${head}tr:w-$size,h-$size,c-maintain_ratio,fo-auto/$tail';
  }

  /// A width-constrained version for a large single image, where the
  /// height should follow the photo's own proportions.
  static String wide(String url, {int width = 720}) {
    final at = url.indexOf(_marker);
    if (at < 0) return url;
    final afterHost = at + _marker.length;
    final slash = url.indexOf('/', afterHost);
    if (slash < 0) return url;
    if (url.startsWith('tr:', slash + 1)) return url;

    final head = url.substring(0, slash + 1);
    final tail = url.substring(slash + 1);
    return '${head}tr:w-$width/$tail';
  }
}
