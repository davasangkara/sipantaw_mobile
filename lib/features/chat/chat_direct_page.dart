import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/theme/app_theme.dart';

class ChatDirectPage extends StatefulWidget {
  final int receiverId;
  final String receiverNama;

  const ChatDirectPage({
    super.key,
    required this.receiverId,
    required this.receiverNama,
  });

  @override
  State<ChatDirectPage> createState() => _ChatDirectPageState();
}

class _ChatDirectPageState extends State<ChatDirectPage> {
  static const _teal = AppColors.teal;
  static const _tealDark = AppColors.tealDeep;
  static const _tealLight = AppColors.tealSoft;
  static const _bg = AppColors.bg;
  static const _textDark = AppColors.textPrimary;

  List _messages = [];
  bool _loading = true;
  bool _sending = false;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get(
          '${ApiConfig.chat}/direct/${widget.receiverId}');
      setState(() {
        _messages = res.data['messages'] ?? [];
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _sending) return;

    _msgController.clear();
    setState(() => _sending = true);

    try {
      final res = await ApiClient.post(
        '${ApiConfig.chat}/direct/send',
        data: {
          'message': text,
          'receiver_id': widget.receiverId,
        },
      );
      final newMsg = res.data['data'];
      setState(() => _messages.add(newMsg));
      _scrollToBottom();
    } catch (e) {
      _msgController.text = text;
    } finally {
      setState(() => _sending = false);
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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: _textDark),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _tealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.receiverNama.isNotEmpty
                      ? widget.receiverNama[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pesan Langsung',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    widget.receiverNama,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _loadMessages,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _tealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded, color: _teal, size: 18),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.withOpacity(0.08)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _teal, strokeWidth: 2.5),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: _teal,
                    onRefresh: _loadMessages,
                    child: _messages.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
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
                                        'Mulai percakapan dengan ${widget.receiverNama}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400]),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) =>
                                _buildBubble(_messages[i]),
                          ),
                  ),
                ),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildBubble(Map msg) {
    final isMine = msg['is_mine'] == true;
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _tealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.receiverNama.isNotEmpty
                      ? widget.receiverNama[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
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
                  padding:
                      const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    time,
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 6),
        ],
      ),
    );
  }

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
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
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
}