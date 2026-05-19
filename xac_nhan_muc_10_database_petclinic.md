# Xác nhận mục 10: Những điểm cần duyệt trước khi tạo SQL

Tài liệu này ghi lại các quyết định đã được xác nhận cho phần **“10. Những điểm cần bạn duyệt trước khi tạo SQL”** của bản tổng hợp database hệ thống **Pet Clinic**. Các quyết định dưới đây sẽ được dùng làm cơ sở khi tạo file script `.sql` cho toàn bộ hệ thống.

---

## 10.1. Mức độ database

### Quyết định đã chốt

Chọn mức độ database: **B - Trung bình**.

### Ý nghĩa khi tạo SQL

Database sẽ được thiết kế đủ cho các Use Case chính của hệ thống, có cấu trúc rõ ràng và chuẩn hóa ở mức phù hợp cho đồ án web.

File SQL sau này sẽ bao gồm:

```sql
CREATE DATABASE
USE database
CREATE TABLE
PRIMARY KEY
FOREIGN KEY
UNIQUE
DEFAULT
CHECK nếu phù hợp
INDEX cơ bản
INSERT INTO dữ liệu mẫu
```

### Định hướng thiết kế

- Không làm quá đơn giản chỉ vài bảng.
- Không làm quá phức tạp như hệ thống thương mại thực tế quy mô lớn.
- Có đầy đủ khóa chính, khóa ngoại và quan hệ giữa các bảng.
- Đủ để triển khai các chức năng chính: tài khoản, thú cưng, đặt lịch, thanh toán, sản phẩm, đơn hàng, bệnh án, nhật ký sức khỏe, blog, cứu trợ, nhận nuôi, AI, tư vấn online, review, voucher và điểm thưởng.

---

## 10.2. Thanh toán

### Quyết định đã chốt

- Thanh toán cần lưu **chi tiết giao dịch**.
- Có dùng chung bảng `payments`.
- Bảng `receipts` và `refunds` phải được **tách riêng**.

### Ý nghĩa khi tạo SQL

Nhóm bảng thanh toán sẽ được thiết kế theo hướng:

```text
payments
receipts
refunds
```

### Vai trò từng bảng

| Bảng | Mục đích |
|---|---|
| `payments` | Lưu thông tin giao dịch thanh toán chính cho dịch vụ, đơn hàng hoặc tư vấn online |
| `receipts` | Lưu biên lai sau khi giao dịch thanh toán thành công |
| `refunds` | Lưu thông tin hoàn tiền khi khách hủy lịch hoặc phát sinh giao dịch cần hoàn tiền |

### Ghi chú thiết kế

Bảng `payments` sẽ nên hỗ trợ nhiều loại đối tượng thanh toán, ví dụ:

```text
appointment
order
online_consultation
```

Nhờ vậy, hệ thống có thể dùng chung một bảng thanh toán cho nhiều nghiệp vụ khác nhau, nhưng vẫn tách biên lai và hoàn tiền để dễ quản lý, truy vết và mở rộng.

---

## 10.3. Bác sĩ, nhân viên và admin

### Quyết định đã chốt

- Bác sĩ có tài khoản đăng nhập riêng.
- Nhân viên có quyền xác nhận thanh toán tại cửa hàng.
- Admin có quyền quản lý toàn bộ sản phẩm, dịch vụ, bài viết, nhận nuôi/cứu trợ và review.

### Ý nghĩa khi tạo SQL

Database sẽ có hệ thống tài khoản và vai trò rõ ràng.

Các role chính gồm:

```text
ADMIN
STAFF
DOCTOR
CUSTOMER
```

### Nhóm bảng liên quan dự kiến

```text
roles
users
doctors
staff_profiles
```

### Phân quyền tổng quát

| Role | Quyền chính |
|---|---|
| `CUSTOMER` | Đăng ký, đăng nhập, quản lý thú cưng, đặt lịch, mua hàng, viết nhật ký, nhận nuôi, đánh giá |
| `DOCTOR` | Đăng nhập, xem lịch khám/tư vấn, xác nhận hoặc từ chối tư vấn online, ghi chú y khoa, tạo hồ sơ bệnh án |
| `STAFF` | Xác nhận thanh toán tại cửa hàng, hỗ trợ xử lý lịch hẹn, đơn hàng hoặc dịch vụ |
| `ADMIN` | Quản lý toàn bộ hệ thống: sản phẩm, dịch vụ, bài viết, cứu trợ, nhận nuôi, review, tài khoản và dữ liệu nền |

### Ghi chú thiết kế

Bác sĩ và nhân viên đều là người dùng có tài khoản trong bảng `users`, nhưng có thêm bảng hồ sơ riêng để lưu thông tin chuyên biệt.

Ví dụ:

```text
users.user_id
↓
doctors.user_id
```

hoặc:

```text
users.user_id
↓
staff_profiles.user_id
```

---

## 10.4. Online consultation

### Quyết định đã chốt

- Tư vấn online sẽ **tách riêng** thành bảng `online_consultations`.
- Không dùng chung hoàn toàn với bảng `appointments`.
- Chat/video cần lưu dữ liệu thật vào database, không chỉ mô phỏng giao diện.

### Ý nghĩa khi tạo SQL

Phần tư vấn online sẽ có nhóm bảng riêng, dự kiến gồm:

```text
online_consultations
consultation_rooms
consultation_messages
consultation_attachments
```

### Vai trò từng bảng

| Bảng | Mục đích |
|---|---|
| `online_consultations` | Lưu lịch tư vấn online giữa khách hàng và bác sĩ |
| `consultation_rooms` | Lưu thông tin phòng chat/video riêng cho từng lịch tư vấn |
| `consultation_messages` | Lưu tin nhắn trao đổi giữa khách hàng và bác sĩ |
| `consultation_attachments` | Lưu file ảnh/video/tệp đính kèm trong quá trình tư vấn |

### Trạng thái nên hỗ trợ

```text
pending
confirmed
rejected
cancelled
missed
completed
```

### Ghi chú thiết kế

Tư vấn online có luồng nghiệp vụ khác lịch khám thường:

- Người dùng chọn bác sĩ và khung giờ online.
- Người dùng nhập mô tả triệu chứng, đính kèm ảnh/video.
- Bác sĩ xác nhận hoặc từ chối.
- Nếu xác nhận, hệ thống tạo phòng chat/video riêng.
- Tin nhắn, file và ghi chú bác sĩ được lưu lại để phục vụ hồ sơ y tế.

Vì vậy, tách riêng `online_consultations` sẽ giúp database rõ ràng và dễ code hơn.

---

## 10.5. Blog và cứu trợ

### Quyết định đã chốt

- Blog và cứu trợ sẽ được tách riêng.
- Không dùng chung bảng `posts` với `post_type = rescue`.
- Bài cứu trợ sẽ có bảng riêng `rescue_posts`.

### Ý nghĩa khi tạo SQL

Nhóm blog/bài viết sẽ dùng cho:

```text
Blog nền tảng
Bài viết cộng đồng
```

Dự kiến các bảng:

```text
posts
post_categories
comments
```

Nhóm cứu trợ sẽ tách riêng, dự kiến gồm:

```text
rescue_posts
rescue_stations
rescue_links
```

### Lý do tách riêng

Blog và cứu trợ có mục đích khác nhau:

| Nhóm | Mục đích |
|---|---|
| Blog | Chia sẻ kiến thức, bài viết nền tảng, bài cộng đồng |
| Cứu trợ | Thông tin cứu trợ, trạm cứu trợ, liên kết quyên góp, fanpage, số điện thoại hỗ trợ |

Nếu dùng chung một bảng `posts` cho cả blog và cứu trợ, database có thể bị lẫn dữ liệu và khó mở rộng. Vì vậy, tách `rescue_posts` là phù hợp hơn với hệ thống Pet Clinic này.

---

## 10.6. Review

### Quyết định đã chốt

Review sẽ làm theo khuyến nghị trong file tổng hợp database.

### Ý nghĩa khi tạo SQL

Review sẽ có bảng riêng, dự kiến là:

```text
reviews
```

Bảng này cần hỗ trợ:

```text
rating từ 1 đến 5
comment nội dung đánh giá
trạng thái kiểm duyệt
admin duyệt / từ chối / xóa mềm
liên kết tới dịch vụ hoặc bác sĩ
```

### Trạng thái review nên có

```text
pending
approved
rejected
deleted
```

### Luồng xử lý review

1. Khách hàng chỉ được đánh giá sau khi đã sử dụng dịch vụ hoặc có đơn hàng hoàn thành.
2. Khi gửi đánh giá, review được lưu với trạng thái `pending`.
3. Admin kiểm duyệt nội dung.
4. Nếu hợp lệ, admin chuyển trạng thái sang `approved`.
5. Review đã duyệt mới được hiển thị công khai.
6. Nếu spam hoặc không phù hợp, admin có thể `rejected` hoặc xóa mềm.
7. Khi review được duyệt, hệ thống có thể cập nhật điểm đánh giá trung bình cho dịch vụ hoặc bác sĩ.

### Các bảng có thể bị ảnh hưởng bởi review

```text
services

doctors
```

Có thể lưu thêm các cột như:

```text
average_rating
review_count
```

để tối ưu hiển thị trên giao diện.

---

## Tổng kết các quyết định đã chốt

| Mục | Quyết định |
|---|---|
| 10.1. Mức độ database | Mức B - Trung bình, đầy đủ khóa chính/khóa ngoại, đủ Use Case chính |
| 10.2. Thanh toán | Dùng chung `payments`, tách riêng `receipts` và `refunds` |
| 10.3. Bác sĩ/nhân viên/admin | Bác sĩ có login riêng, staff xác nhận thanh toán tại cửa hàng, admin quản lý toàn bộ hệ thống |
| 10.4. Online consultation | Tách riêng `online_consultations`, lưu thật chat/video vào database |
| 10.5. Blog và cứu trợ | Blog dùng `posts`, cứu trợ tách riêng `rescue_posts` |
| 10.6. Review | Có kiểm duyệt, trạng thái pending/approved/rejected/deleted, cập nhật điểm trung bình |

---

## Ghi chú cho bước tạo file SQL sau này

Khi tạo file script `.sql`, các quyết định trong tài liệu này sẽ được xem là cấu hình chính thức để thiết kế database.

Các nhóm bảng quan trọng cần có trong SQL sau này gồm:

```text
roles
users
user_sessions
otp_codes
notifications
pets
pet_species
pet_breeds
pet_images
branches
doctors
staff_profiles
specialties
doctor_specialties
doctor_schedules
time_slots
service_categories
services
appointments
appointment_services
appointment_status_history
payments
receipts
refunds
products
product_categories
product_images
carts
cart_items
orders
order_items
order_status_history
medical_records
prescriptions
prescription_items
health_diaries
care_reminders
posts
post_categories
comments
first_aid_guides
first_aid_steps
first_aid_media
rescue_posts
rescue_stations
rescue_links
adoption_pets
adoption_pet_images
adoption_requests
ai_chat_sessions
ai_chat_messages
online_consultations
consultation_rooms
consultation_messages
consultation_attachments
reviews
vouchers
voucher_usages
loyalty_point_transactions
contact_messages
```

