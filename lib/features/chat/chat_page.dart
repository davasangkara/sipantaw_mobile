import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/premium_widgets.dart';
import 'chat_direct_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  late TabController _tabController;

  List _messages = [];
  bool _loadingChat = true;
  bool _sending = false;
  String _roomNama = 'Chat Unit';
  int? _myPegawaiId;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  List _pegawaiList = [];
  bool _loadingPegawai = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroupChat();
    _loadPegawai();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupChat() async {
    setState(() => _loadingChat = true);
    try {
      final res = await ApiClient.get(ApiConfig.chat);
      final data = res.data['data'];
      setState(() {
        _roomNama = data['room']['nama'] ?? 'Chat Unit';
        _messages = data['messages'] ?? [];
        _loadingChat = false;
        final mine = (_messages as List)
            .firstWhere((m) => m['is_mine'] == true, orElse: () => null);
        if (mine != null) _myPegawaiId = mine['pegawai_id'];
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _loadingChat = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _sending) return;

    _msgController.clear();
    setState(() => _sending = true);

    try {
      final res = await ApiClient.post('${ApiConfig.chat}/send',
          data: {'message': text});
      final newMsg = res.data['data'];
      setState(() => _messages.add(newMsg));
      _scrollToBottom();
    } catch (e) {
      _msgController.text = text;
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _loadPegawai() async {
    setState(() => _loadingPegawai = true);
    try {
      final res = await ApiClient.get('${ApiConfig.chat}/pegawai');
      setState(() {
        _pegawaiList = res.data['data'] ?? [];
        _loadingPegawai = false;
      });
    } catch (e) {
      setState(() => _loadingPegawai = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.canvas,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 72,
            titleSpacing: 20,
            leading: Padding(
              padding: const EdgeInsets.all(14),
              child: PressableScale(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppShadows.xs,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.textPrimary),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tabController.index == 0 ? _roomNama : 'Percakapan',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  _tabController.index == 0 ? 'Grup Unit' : 'Pesan Langsung',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.black,
                indicatorWeight: 2.5,
                labelColor: AppColors.black,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                onTap: (_) => setState(() {}),
                tabs: const [
                  Tab(icon: Icon(Icons.group_rounded, size: 18), text: 'Grup Unit'),
                  Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Langsung'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGroupChat(),
            _buildDirectList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChat() {
    if (_loadingChat) {
      return const Center(
        child: CircularProgressIndicator(color: _teal, strokeWidth: 2.5),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: _teal,
            onRefresh: _loadGroupChat,
            child: _messages.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: _tealLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 36,
                                  color: _teal,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada pesan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mulai percakapan dengan rekan unit',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _buildBubble(_messages[i]),
                  ),
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildBubble(Map msg) {
    final isMine = msg['is_mine'] == true;
    final nama = msg['nama']?.toString() ?? '-';
    final text = msg['message']?.toString() ?? '';
    final time = msg['sent_at']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _avatar(nama),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      nama,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMine ? _teal : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMine ? 14 : 2),
                      bottomRight: Radius.circular(isMine ? 2 : 14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      color: isMine ? Colors.white : _textDark,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    time,
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 6),
            _avatar(nama, mine: true),
          ],
        ],
      ),
    );
  }

  Widget _avatar(String nama, {bool mine = false}) => CircleAvatar(
        radius: 16,
        backgroundColor: mine ? _tealLight : Colors.grey[200],
        child: Text(
          nama.isNotEmpty ? nama[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: mine ? _teal : Colors.grey[600],
          ),
        ),
      );

  Widget _buildInputBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle:
                        TextStyle(color: Colors.grey[400], fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: _teal),
                    ),
                    filled: true,
                    fillColor: _bg,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_teal, _tealDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _teal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDirectList() {
    if (_loadingPegawai) {
      return const Center(
        child: CircularProgressIndicator(color: _teal, strokeWidth: 2.5),
      );
    }

    if (_pegawaiList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _tealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 36,
                color: _teal,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada pegawai lain',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Belum ada pegawai lain di unit ini',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _teal,
      onRefresh: _loadPegawai,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _pegawaiList.length,
        itemBuilder: (context, i) {
          final p = _pegawaiList[i];
          final nama = p['nama']?.toString() ?? '-';
          final jabatan = p['jabatan']?.toString() ?? '';
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDirectPage(
                  receiverId: int.parse(p['id'].toString()),
                  receiverNama: nama,
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _tealLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _teal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (jabatan.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.work_outline_rounded,
                                  size: 11, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  jabatan,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _tealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: _teal, size: 18),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}