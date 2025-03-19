import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:letsgo/providers/review_provider.dart';
import 'package:letsgo/providers/auth_provider.dart';
import 'package:letsgo/models/review.dart';
import 'package:intl/intl.dart';

class ReviewsScreen extends StatelessWidget {
  final String tripId;
  final String userId;
  final bool isDriver;

  const ReviewsScreen({
    super.key,
    required this.tripId,
    required this.userId,
    this.isDriver = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отзывы'),
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, reviewProvider, child) {
          if (reviewProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reviewProvider.error != null) {
            return Center(
              child: Text(
                reviewProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (reviewProvider.reviews.isEmpty) {
            return const Center(
              child: Text('Отзывов пока нет'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviewProvider.reviews.length,
            itemBuilder: (context, index) {
              final review = reviewProvider.reviews[index];
              return _buildReviewCard(review, context);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReviewDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReviewCard(Review review, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(review.reviewerName[0]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy').format(review.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оставить отзыв'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      rating = index + 1;
                    },
                  ),
                ),
              ),
              TextFormField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Комментарий',
                  hintText: 'Опишите ваши впечатления',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите комментарий';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await reviewProvider.createReview(
                  tripId: tripId,
                  reviewerId: authProvider.userId!,
                  reviewedId: userId,
                  rating: rating,
                  comment: commentController.text,
                  token: authProvider.token!,
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Отзыв успешно добавлен'),
                    ),
                  );
                }
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
} 