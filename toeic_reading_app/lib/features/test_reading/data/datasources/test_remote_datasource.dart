import 'package:cloud_firestore/cloud_firestore.dart'; // <<< ĐÃ THÊM: Import Firestore
import '../../../../core/error/exceptions.dart';
import '../models/test_model.dart';

abstract class TestRemoteDataSource {
  Future<List<TestModel>> fetchAvailableTests();
  Future<TestModel> fetchTestDetails(String testId);
// Future<ResultModel> sendUserAnswers(String testId, Map<String, int> answers);
}

class TestRemoteDataSourceImpl implements TestRemoteDataSource {
  // Dùng DI để inject Firestore instance
  final FirebaseFirestore firestore; // <<< ĐÃ THÊM: Tham số Firestore

  TestRemoteDataSourceImpl({required this.firestore}); // <<< Cập nhật Constructor

  // --- LẤY DANH SÁCH BÀI TEST ---
  @override
  Future<List<TestModel>> fetchAvailableTests() async {
    try {
      // 1. Tham chiếu đến Collection 'tests' và lấy danh sách (documents)
      final querySnapshot = await firestore
          .collection('tests')
          .get(); // Có thể thêm .orderBy('title') nếu cần

      // 2. Chuyển đổi List<QueryDocumentSnapshot> sang List<TestModel>
      return querySnapshot.docs.map((doc) {
        // Lấy dữ liệu và gán ID của Document vào trường 'id' của TestModel
        final data = doc.data();
        data['id'] = doc.id;
        return TestModel.fromJson(data);
      }).toList();

    } on FirebaseException catch (e) {
      // Xử lý lỗi từ Firebase
      throw ServerException(message: 'Lỗi Firebase khi tải danh sách test: ${e.message}');
    } catch (e) {
      // Xử lý lỗi không xác định
      throw ServerException(message: 'Lỗi không xác định khi tải test.');
    }
  }

  // --- LẤY CHI TIẾT BÀI TEST ---
  @override
  Future<TestModel> fetchTestDetails(String testId) async {
    try {
      // 1. Lấy Document chi tiết của bài test
      final testDoc = await firestore
          .collection('tests')
          .doc(testId)
          .get();

      if (!testDoc.exists) {
        throw ServerException(message: 'Không tìm thấy bài test với ID: $testId');
      }

      // 2. Lấy dữ liệu questions từ subcollection
      final questionsSnapshot = await testDoc.reference
          .collection('questions')
          .orderBy('question_index') // Giả định có trường này để sắp xếp
          .get();

      // 3. Xử lý dữ liệu
      final testData = testDoc.data()!;

      // Ánh xạ danh sách Questions Model
      final List<Map<String, dynamic>> questionList = questionsSnapshot.docs.map((qDoc) {
        final qData = qDoc.data();
        qData['id'] = qDoc.id; // Dùng ID của question document
        return qData;
      }).toList();

      // Gán ID và danh sách câu hỏi vào dữ liệu bài test
      testData['id'] = testDoc.id;
      testData['questions'] = questionList;

      return TestModel.fromJson(testData);

    } on FirebaseException catch (e) {
      throw ServerException(message: 'Lỗi Firebase khi tải chi tiết test: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Lỗi không xác định khi tải chi tiết test.');
    }
  }
}