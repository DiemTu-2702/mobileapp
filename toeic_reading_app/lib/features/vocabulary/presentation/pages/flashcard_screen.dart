import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FlashcardScreen extends StatefulWidget {
  final String topicId;
  final String topicName;
  final String topicDescription;

  const FlashcardScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.topicDescription,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late FlutterTts flutterTts;

  late Stream<QuerySnapshot> _vocabStream;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initTts();

    // 👇 2. Khởi tạo Stream 1 lần duy nhất ở đây
    _vocabStream = FirebaseFirestore.instance
        .collection('topics')
        .doc(widget.topicId)
        .collection('words')
        .snapshots();

    _pageController = PageController();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> updateWordStatus(String wordId, bool isMastered) async {
    try {
      await FirebaseFirestore.instance
          .collection('topics')
          .doc(widget.topicId)
          .collection('words')
          .doc(wordId)
          .update({
        'isMastered': isMastered,
        'lastReviewed': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMastered ? "Đã đánh dấu: ĐÃ THUỘC 🎉" : "Đã đánh dấu: HỌC LẠI 🧠"),
            duration: const Duration(milliseconds: 500),
            backgroundColor: isMastered ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Lỗi update: $e");
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    _pageController.dispose(); // Nhớ giải phóng controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 👇 3. Dùng biến _vocabStream đã tạo ở initState
    return StreamBuilder<QuerySnapshot>(
      stream: _vocabStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.topicName)),
            body: const Center(child: Text('Chưa có từ vựng nào.')),
          );
        }

        final words = snapshot.data!.docs;
        final isLastPage = _currentIndex == words.length - 1;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  widget.topicName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  widget.topicDescription,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            actions: [
              if (isLastPage)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      children: [
                        Text("Hoàn tất", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.check_circle, size: 18),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController, // Gắn controller vào đây
                  itemCount: words.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final vocabDoc = words[index];
                    final vocabData = vocabDoc.data() as Map<String, dynamic>;

                    return Center(
                      child: FlashcardItem(
                        key: ValueKey(vocabDoc.id),
                        english: vocabData['englishWord'] ?? '',
                        vietnamese: vocabData['vietnameseDefinition'] ?? '',
                        type: vocabData['partOfSpeech'] ?? '',
                        ipa: vocabData['pronunciation'] ?? '',
                        isMastered: vocabData['isMastered'] ?? false,
                        index: index + 1,
                        total: words.length,
                        onSpeak: () => _speak(vocabData['englishWord'] ?? ''),
                        onStatusChanged: (bool mastered) {
                          updateWordStatus(vocabDoc.id, mastered);
                        },
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: isLastPage
                    ? const Text(
                  "🎉 Bạn đã xem hết từ vựng!",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                )
                    : const Text(
                  "Vuốt sang trái để học từ tiếp theo 👉",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class FlashcardItem extends StatefulWidget {
  final String english;
  final String vietnamese;
  final String type;
  final String ipa;
  final bool isMastered;
  final int index;
  final int total;
  final VoidCallback onSpeak;
  final Function(bool) onStatusChanged;

  const FlashcardItem({
    super.key,
    required this.english,
    required this.vietnamese,
    required this.type,
    required this.ipa,
    required this.isMastered,
    required this.index,
    required this.total,
    required this.onSpeak,
    required this.onStatusChanged,
  });

  @override
  State<FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<FlashcardItem> {
  bool _isFlipped = false;

  @override
  void didUpdateWidget(covariant FlashcardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.english != widget.english) {
      _isFlipped = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isFlipped = !_isFlipped),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (widget, animation) {
          final rotateAnim = Tween(begin: 3.14, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: widget,
            builder: (context, child) {
              final angle = rotateAnim.value;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: _isFlipped ? _buildBack() : _buildFront(),
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      key: const ValueKey(true),
      width: 300,
      height: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
        ],
        border: widget.isMastered ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20, left: 0, right: 0,
            child: Center(child: Text('${widget.index}/${widget.total}', style: const TextStyle(color: Colors.grey))),
          ),
          if (widget.isMastered)
            const Positioned(
              top: 10, left: 10,
              child: Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
          Positioned(
            top: 10, right: 10,
            child: IconButton(
              onPressed: widget.onSpeak,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.volume_up, color: Color(0xFF1565C0), size: 28),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.english, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.ipa, style: const TextStyle(fontSize: 20, color: Colors.redAccent, fontFamily: 'Arial')),
                ),
                const SizedBox(height: 12),
                Text(widget.type, style: const TextStyle(fontSize: 18, color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const Positioned(
            bottom: 20, left: 0, right: 0,
            child: Center(child: Text("Chạm để xem nghĩa", style: TextStyle(color: Colors.grey))),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      key: const ValueKey(false),
      width: 300,
      height: 480,
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              widget.vietnamese,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onStatusChanged(false),
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    label: const Text("Học lại", style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onStatusChanged(true),
                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                    label: const Text("Đã thuộc", style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}