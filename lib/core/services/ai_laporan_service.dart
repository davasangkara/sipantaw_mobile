import 'dart:convert';
import 'package:dio/dio.dart';

/// Service untuk generate laporan WFA otomatis menggunakan AI.
/// Menggunakan Amazon Bedrock / Kiro AI API.
class AiLaporanService {
  // Kiro AI menggunakan Amazon Bedrock Claude
  static const _apiUrl =
      'https://bedrock-runtime.us-east-1.amazonaws.com/model/anthropic.claude-3-5-sonnet-20241022-v2:0/invoke';

  // API Key dari environment / config
  // Untuk development, gunakan key yang disediakan
  static const _apiKey = 'YOUR_KIRO_API_KEY'; // Ganti dengan API key Kiro

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': _apiKey,
    },
  ));

  /// Generate laporan WFA lengkap berdasarkan konteks pegawai
  static Future<LaporanAiResult> generateLaporan({
    required String namaKegiatan,
    required String jabatan,
    required String unit,
    required String tanggal,
    required String hari,
    String? alamat,
    String? kota,
  }) async {
    final prompt = _buildPrompt(
      namaKegiatan: namaKegiatan,
      jabatan: jabatan,
      unit: unit,
      tanggal: tanggal,
      hari: hari,
      alamat: alamat,
      kota: kota,
    );

    try {
      final response = await _dio.post(
        _apiUrl,
        data: jsonEncode({
          'anthropic_version': 'bedrock-2023-05-31',
          'max_tokens': 2048,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      );

      final content = response.data['content'][0]['text'] as String;
      return _parseResponse(content);
    } on DioException catch (_) {
      // Fallback: generate lokal jika API tidak tersedia
      return _generateFallback(
        namaKegiatan: namaKegiatan,
        jabatan: jabatan,
        unit: unit,
        tanggal: tanggal,
        hari: hari,
        alamat: alamat,
        kota: kota,
      );
    } catch (e) {
      return _generateFallback(
        namaKegiatan: namaKegiatan,
        jabatan: jabatan,
        unit: unit,
        tanggal: tanggal,
        hari: hari,
        alamat: alamat,
        kota: kota,
      );
    }
  }

  static String _buildPrompt({
    required String namaKegiatan,
    required String jabatan,
    required String unit,
    required String tanggal,
    required String hari,
    String? alamat,
    String? kota,
  }) {
    return '''Kamu adalah asisten untuk mengisi laporan kerja WFA (Work From Anywhere) pegawai pemerintah Indonesia.

Data pegawai:
- Jabatan: $jabatan
- Unit: $unit
- Tanggal: $tanggal ($hari)
- Jenis Kegiatan: $namaKegiatan
${alamat != null ? '- Lokasi: $alamat, $kota' : ''}

Buatkan laporan WFA yang profesional dan realistis dalam format JSON berikut:
{
  "uraian_kinerja": ["uraian 1", "uraian 2", "uraian 3"],
  "efisiensi": [
    {"uraian": "deskripsi efisiensi yang dicapai"}
  ],
  "hambatan": [
    {"uraian": "hambatan yang dihadapi dan solusinya"}
  ],
  "link_output": null
}

Ketentuan:
- Uraian kinerja: 2-3 poin, spesifik, menggunakan kata kerja aktif, relevan dengan jabatan dan kegiatan
- Efisiensi: 1-2 poin, fokus pada hasil positif yang dicapai
- Hambatan: 1 poin, realistis dan profesional
- Gunakan bahasa Indonesia formal
- Sesuaikan dengan konteks jabatan: $jabatan di unit $unit

Balas HANYA dengan JSON valid, tanpa penjelasan tambahan.''';
  }

  static LaporanAiResult _parseResponse(String content) {
    try {
      // Cari JSON dalam response
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}') + 1;
      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('No JSON found');
      }
      final jsonStr = content.substring(jsonStart, jsonEnd);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      return LaporanAiResult(
        uraianKinerja: (data['uraian_kinerja'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        efisiensi: (data['efisiensi'] as List?)
                ?.map((e) => AiEfisiensiItem(
                      uraian: e['uraian']?.toString() ?? '',
                    ))
                .toList() ??
            [],
        hambatan: (data['hambatan'] as List?)
                ?.map((e) => AiHambatanItem(
                      uraian: e['uraian']?.toString() ?? '',
                    ))
                .toList() ??
            [],
        linkOutput: data['link_output']?.toString(),
      );
    } catch (_) {
      return _generateFallbackFromKegiatan('Kegiatan WFA');
    }
  }

  /// Fallback generator lokal jika AI API tidak tersedia
  static LaporanAiResult _generateFallback({
    required String namaKegiatan,
    required String jabatan,
    required String unit,
    required String tanggal,
    required String hari,
    String? alamat,
    String? kota,
  }) {
    return LaporanAiResult(
      uraianKinerja: [
        'Melaksanakan $namaKegiatan sesuai dengan tugas pokok dan fungsi jabatan $jabatan',
        'Menyusun dan mendokumentasikan hasil pelaksanaan kegiatan secara sistematis',
        'Berkoordinasi dengan rekan kerja di unit $unit melalui media komunikasi digital',
      ],
      efisiensi: [
        AiEfisiensiItem(
          uraian:
              'Pelaksanaan kegiatan WFA berjalan efektif dengan memanfaatkan teknologi informasi sehingga produktivitas tetap terjaga',
        ),
      ],
      hambatan: [
        AiHambatanItem(
          uraian:
              'Koneksi internet sesekali tidak stabil, diatasi dengan menggunakan hotspot cadangan',
        ),
      ],
      linkOutput: null,
    );
  }

  static LaporanAiResult _generateFallbackFromKegiatan(String kegiatan) {
    return LaporanAiResult(
      uraianKinerja: [
        'Melaksanakan $kegiatan dengan optimal',
        'Mendokumentasikan hasil kegiatan secara sistematis',
      ],
      efisiensi: [
        AiEfisiensiItem(uraian: 'Kegiatan berjalan efektif dan efisien'),
      ],
      hambatan: [
        AiHambatanItem(uraian: 'Tidak ada hambatan berarti dalam pelaksanaan'),
      ],
      linkOutput: null,
    );
  }
}

class LaporanAiResult {
  final List<String> uraianKinerja;
  final List<AiEfisiensiItem> efisiensi;
  final List<AiHambatanItem> hambatan;
  final String? linkOutput;

  const LaporanAiResult({
    required this.uraianKinerja,
    required this.efisiensi,
    required this.hambatan,
    this.linkOutput,
  });
}

class AiEfisiensiItem {
  final String uraian;
  const AiEfisiensiItem({required this.uraian});
}

class AiHambatanItem {
  final String uraian;
  const AiHambatanItem({required this.uraian});
}
