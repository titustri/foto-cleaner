import 'package:photo_manager/photo_manager.dart';

class PhotoService {
  static const int batchSize = 20;

  AssetPathEntity? _allPhotosAlbum;
  int _currentOffset = 0;
  int _totalCount = 0;

  Future<bool> requestPermission() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    return state.isAuth;
  }

  Future<void> initialize() async {
    // Load semua foto, urutkan dari terlama (asc = true)
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: true),
        ],
      ),
    );

    if (albums.isEmpty) return;

    // Cari album "semua foto"
    _allPhotosAlbum = albums.firstWhere(
      (album) => album.isAll,
      orElse: () => albums.first,
    );

    _totalCount = await _allPhotosAlbum!.assetCountAsync;
    _currentOffset = 0;
  }

  Future<List<AssetEntity>> getNextBatch() async {
    if (_allPhotosAlbum == null || _currentOffset >= _totalCount) return [];

    final int end = (_currentOffset + batchSize).clamp(0, _totalCount);

    final List<AssetEntity> assets = await _allPhotosAlbum!.getAssetListRange(
      start: _currentOffset,
      end: end,
    );

    _currentOffset = end;
    return assets;
  }

  /// Trigger system dialog untuk delete (wajib di Android 10+)
  Future<void> deleteAssets(List<AssetEntity> assets) async {
    if (assets.isEmpty) return;
    final List<String> ids = assets.map((a) => a.id).toList();
    await PhotoManager.editor.deleteWithIds(ids);
  }

  int get totalCount => _totalCount;
  int get currentOffset => _currentOffset;
  bool get hasMore => _currentOffset < _totalCount;
}
