# Payment Integration TODO

## Current Status
- Backend has Razorpay configured with `/api/create-payment` endpoint
- Flutter app has dummy payment dialog for online payments
- Need to integrate Razorpay Flutter SDK for real payments

## Tasks
- [x] Add Razorpay Flutter dependency to pubspec.yaml
- [x] Update upload_order_page.dart to integrate Razorpay payment flow
- [x] Replace dummy payment dialog with actual Razorpay payment initiation
- [x] Handle payment success/failure callbacks
- [x] Add createPayment method to ApiService
- [x] Update Order model to include amount field
- [ ] Update order status after successful payment
- [ ] Test payment integration
