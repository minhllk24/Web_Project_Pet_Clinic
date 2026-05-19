# Tổng thể database cần tạo cho hệ thống Pet Clinic

> Trạng thái tài liệu: **Bản tổng hợp để đọc và duyệt trước khi tạo file `.sql`**  
> Chưa phải script SQL cuối cùng. Tài liệu này dùng để thống nhất phạm vi database, danh sách bảng, quan hệ chính và các ràng buộc nghiệp vụ quan trọng.

---

## 1. Nguồn yêu cầu đã tổng hợp

Tài liệu này được tổng hợp từ toàn bộ thông tin bạn đã gửi về hệ thống Pet Clinic, gồm:

1. Sơ đồ chức năng tổng thể của website.
2. User Story của hệ thống.
3. Bộ 5 file đặc tả Use Case bản mới:
   - `Đặc tả usecase part1(1).docx`
   - `Đặc tả usecase part2(1).docx`
   - `Đặc tả usecase part3(1).docx`
   - `Đặc tả usecase part4(1).docx`
   - `Đặc tả usecase part5(1).docx`

5 file cũ đã được bỏ qua vì bạn nói có lỗi bóp méo cột. Bản tổng hợp này lấy 5 file mới có hậu tố `(1)` làm nguồn chính.

---

## 2. Mục tiêu database

Database cần phục vụ một website Pet Clinic / Pet Service / Pet Shop tương tự ý tưởng PetPro, bao gồm:

- Tài khoản người dùng, đăng ký, đăng nhập, OTP, quên mật khẩu.
- Phân quyền: khách hàng, admin, bác sĩ, nhân viên.
- Quản lý hồ sơ thú cưng.
- Đặt lịch khám, spa, dịch vụ thú y.
- Lịch sử đặt lịch, đổi lịch, hủy lịch, chống trùng khung giờ.
- Thanh toán dịch vụ và đơn hàng.
- Bán sản phẩm thú cưng, giỏ hàng, đặt hàng, tồn kho.
- Hồ sơ bệnh án, đơn thuốc, nhật ký theo dõi sức khỏe.
- Nhắc tiêm phòng, tẩy giun, khám định kỳ, lịch chăm sóc.
- Blog nền tảng, bài viết cộng đồng, cẩm nang sơ cứu.
- Cứu trợ động vật và nhận nuôi thú cưng.
- Tư vấn AI theo triệu chứng.
- Tư vấn online với bác sĩ qua chat/video.
- Đánh giá dịch vụ/bác sĩ/sản phẩm/đơn hàng có kiểm duyệt.
- Tích điểm khách hàng thân thiết.
- Voucher/mã khuyến mãi.
- Thông báo in-app/email/SMS.

---

## 3. Nguyên tắc thiết kế database đề xuất

Nên thiết kế theo hướng **vừa đủ chi tiết cho đồ án web**, nhưng vẫn có cấu trúc rõ ràng để code dễ mở rộng.

### 3.1. Chuẩn kỹ thuật nên dùng

- Hệ quản trị: **MySQL 8.x**.
- Engine: `InnoDB` để hỗ trợ khóa ngoại.
- Charset: `utf8mb4`.
- Collation khuyến nghị: `utf8mb4_unicode_ci` hoặc `utf8mb4_0900_ai_ci`.
- Khóa chính: `BIGINT UNSIGNED AUTO_INCREMENT`.
- Các bảng chính nên có:
  - `created_at`
  - `updated_at`
  - `deleted_at` nếu cần xóa mềm.
  - `status` nếu có vòng đời xử lý.

### 3.2. Quy ước đặt tên

- Tên bảng dùng tiếng Anh, dạng số nhiều: `users`, `pets`, `appointments`.
- Tên cột dùng `snake_case`: `user_id`, `created_at`, `phone_number`.
- Khóa chính: `id`.
- Khóa ngoại: `<table_singular>_id`, ví dụ `user_id`, `pet_id`, `doctor_id`.

### 3.3. Lưu ý về mã Use Case

Trong tài liệu có vài mã Use Case bị trùng hoặc dễ nhầm:

- `UC0005` là đặt lịch khám/dịch vụ.
- `UC005` là xem lịch sử đặt lịch.
- `UC0001` là đăng ký tài khoản.
- `UC001` là tư vấn AI.

Vì vậy khi tạo database không nên đặt tên bảng theo mã Use Case, mà nên đặt theo đúng nghiệp vụ thực tế.

---

## 4. Nhóm chức năng và bảng database tương ứng

## 4.1. Nhóm tài khoản, phân quyền, xác thực

### Mục đích

Phục vụ đăng ký, đăng nhập, quên mật khẩu, OTP, session, phân quyền admin/bác sĩ/nhân viên/khách hàng.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `roles` | Lưu vai trò: admin, customer, doctor, staff | Bắt buộc |
| `users` | Lưu tài khoản đăng nhập, email, SĐT, mật khẩu hash, trạng thái | Bắt buộc |
| `user_profiles` | Lưu thông tin hồ sơ cá nhân mở rộng | Nên có |
| `user_addresses` | Lưu địa chỉ giao hàng/địa chỉ liên hệ của người dùng | Nên có |
| `otp_codes` | Lưu OTP đăng ký/quên mật khẩu, thời gian hết hạn, số lần thử | Bắt buộc |
| `user_sessions` | Lưu token/phiên đăng nhập/remember login 30 ngày | Nên có |
| `password_reset_logs` | Lưu lịch sử reset mật khẩu nếu muốn truy vết | Có thể giản lược |
| `notifications` | Lưu thông báo in-app/email/SMS | Bắt buộc nếu có nhắc lịch, đơn hàng, nhận nuôi |

### Gợi ý trường chính

#### `roles`

- `id`
- `name`: `admin`, `customer`, `doctor`, `staff`
- `description`

#### `users`

- `id`
- `role_id`
- `full_name`
- `email`
- `phone_number`
- `password_hash`
- `avatar_url`
- `status`: `active`, `inactive`, `banned`
- `email_verified_at`
- `phone_verified_at`
- `last_login_at`
- `created_at`, `updated_at`, `deleted_at`

### Ràng buộc quan trọng

- `email` nên unique nếu không null.
- `phone_number` nên unique nếu không null.
- Mật khẩu không lưu plaintext, chỉ lưu hash.
- OTP có hiệu lực 5 phút.
- OTP chỉ dùng một lần.
- Cho phép gửi lại OTP sau 60 giây.
- Sau khi đổi mật khẩu, các session cũ nên bị thu hồi.

---

## 4.2. Nhóm hồ sơ thú cưng

### Mục đích

Cho phép khách hàng thêm, sửa, xóa hồ sơ thú cưng, lưu ảnh đại diện, loài, giống, giới tính, cân nặng, sức khỏe, lịch sử tiêm chủng.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `pet_species` | Danh mục loài: chó, mèo, thỏ,... | Bắt buộc |
| `pet_breeds` | Danh mục giống theo loài | Nên có |
| `pets` | Hồ sơ thú cưng thuộc người dùng | Bắt buộc |
| `pet_images` | Lưu nhiều ảnh cho mỗi thú cưng | Nên có |
| `pet_vaccination_histories` | Lưu lịch sử tiêm phòng cũ nếu cần | Nên có |

### Gợi ý trường chính

#### `pets`

- `id`
- `owner_id` → `users.id`
- `species_id` → `pet_species.id`
- `breed_id` → `pet_breeds.id`
- `name`
- `gender`: `male`, `female`, `unknown`
- `date_of_birth`
- `age_text`
- `weight_kg`
- `color`
- `health_note`
- `vaccination_note`
- `profile_image_url`
- `status`: `active`, `inactive`, `deceased`
- `created_at`, `updated_at`, `deleted_at`

### Ràng buộc quan trọng

- Một user có thể có nhiều thú cưng.
- Ảnh hồ sơ thú cưng: JPG/PNG, tối đa 5MB theo đặc tả.
- Người dùng chỉ được quản lý thú cưng của chính mình.

---

## 4.3. Nhóm cơ sở, bác sĩ, chuyên khoa, lịch làm việc

### Mục đích

Phục vụ đặt lịch, lịch sử đặt lịch, tư vấn online, lọc theo bác sĩ/chuyên khoa/dịch vụ.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `branches` | Chi nhánh/nơi khám/địa chỉ phòng khám | Nên có |
| `specialties` | Chuyên khoa thú y | Nên có |
| `doctors` | Hồ sơ bác sĩ, liên kết với tài khoản user | Bắt buộc nếu có bác sĩ |
| `doctor_specialties` | Bác sĩ có thể thuộc nhiều chuyên khoa | Nên có |
| `doctor_schedules` | Lịch làm việc theo ngày/ca | Nên có |
| `time_slots` | Khung giờ có thể đặt | Bắt buộc nếu chống double-booking |

### Gợi ý trường chính

#### `branches`

- `id`
- `name`
- `phone_number`
- `email`
- `address`
- `map_url`
- `status`

#### `doctors`

- `id`
- `user_id` → `users.id`
- `branch_id` → `branches.id`
- `degree`
- `bio`
- `experience_years`
- `phone_number`
- `average_rating`
- `status`

#### `time_slots`

- `id`
- `doctor_id`
- `branch_id`
- `slot_date`
- `start_time`
- `end_time`
- `slot_type`: `clinic`, `online`
- `status`: `available`, `locked`, `booked`, `unavailable`

### Ràng buộc quan trọng

- Không được đặt trùng một khung giờ đã khóa/đã đặt.
- Khi có lịch tư vấn online chờ xác nhận, khung giờ của bác sĩ nên tạm khóa.
- Cần index cho `doctor_id`, `slot_date`, `start_time`, `status`.

---

## 4.4. Nhóm dịch vụ thú y và đặt lịch khám

### Mục đích

Phục vụ đặt lịch dịch vụ khám, spa, điều trị; lưu trạng thái lịch; hỗ trợ đổi/hủy lịch trước 24 giờ.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `service_categories` | Danh mục dịch vụ: khám chữa bệnh, spa,... | Bắt buộc |
| `services` | Dịch vụ cụ thể, giá cơ bản, thời lượng | Bắt buộc |
| `service_price_rules` | Phụ phí theo cân nặng/tuổi/yếu tố khác | Nên có |
| `appointments` | Lịch hẹn khám/dịch vụ | Bắt buộc |
| `appointment_services` | Một lịch có thể gồm nhiều dịch vụ | Nên có |
| `appointment_status_histories` | Lịch sử đổi trạng thái lịch hẹn | Nên có |
| `appointment_attachments` | File/ảnh triệu chứng nếu lịch có đính kèm | Có thể dùng chung với tư vấn online |

### Gợi ý trường chính

#### `services`

- `id`
- `category_id`
- `name`
- `description`
- `base_price`
- `duration_minutes`
- `image_url`
- `average_rating`
- `status`: `active`, `inactive`

#### `appointments`

- `id`
- `appointment_code`
- `customer_id` → `users.id`
- `pet_id` → `pets.id`, nullable nếu đặt cho thú cưng khác
- `branch_id`
- `doctor_id`, nullable nếu chưa phân bác sĩ
- `time_slot_id`
- `appointment_date`
- `start_time`
- `end_time`
- `customer_name`
- `customer_phone`
- `other_pet_info`, nullable
- `symptom_description`
- `note`
- `status`: `pending`, `confirmed`, `cancelled`, `completed`, `rescheduled`, `missed`
- `payment_status`: `unpaid`, `pending`, `paid`, `refunded`, `failed`
- `total_amount`
- `created_at`, `updated_at`, `cancelled_at`

### Ràng buộc quan trọng

- Hỗ trợ chọn thú cưng có sẵn hoặc nhập thú cưng khác.
- Lưu ghi chú khi đặt lịch.
- Lịch sử đặt lịch chỉ hiển thị lịch thuộc tài khoản hiện tại.
- Danh sách lịch nên sắp xếp theo thời gian gần nhất.
- Hỗ trợ hủy/đổi lịch trước hoặc bằng 24 giờ trước giờ hẹn.
- Tránh double-booking bằng unique/index trên `time_slot_id` hoặc tổ hợp `doctor_id + appointment_date + start_time`.

---

## 4.5. Nhóm thanh toán, hóa đơn, biên lai, hoàn tiền

### Mục đích

Phục vụ thanh toán dịch vụ, đơn hàng sản phẩm, tư vấn online, voucher, điểm thưởng, biên lai và hoàn tiền.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `payments` | Giao dịch thanh toán | Bắt buộc |
| `payment_methods` | COD, online, tại cửa hàng, ví điện tử,... | Nên có |
| `payment_transactions` | Log giao dịch với cổng thanh toán | Nên có |
| `refunds` | Hoàn tiền khi hủy lịch/đơn | Nên có |
| `receipts` | Biên lai/hóa đơn gửi cho khách | Nên có |

### Gợi ý trường chính

#### `payments`

- `id`
- `payment_code`
- `user_id`
- `appointment_id`, nullable
- `order_id`, nullable
- `online_consultation_id`, nullable
- `method`: `cod`, `online`, `at_clinic`, `bank_transfer`, `e_wallet`
- `status`: `pending`, `paid`, `failed`, `cancelled`, `refunded`
- `subtotal_amount`
- `voucher_discount_amount`
- `point_discount_amount`
- `total_amount`
- `paid_amount`
- `paid_at`
- `transaction_ref`
- `note`

### Ràng buộc quan trọng

- Một thanh toán nên gắn với một trong các loại: lịch hẹn, đơn hàng, tư vấn online.
- Lưu lịch sử giao dịch để truy vết.
- Nếu thanh toán thất bại, giữ trạng thái chờ thanh toán hoặc cho chọn phương thức khác.
- Nếu hủy lịch sau khi đã thanh toán, cần tạo bản ghi hoàn tiền.

---

## 4.6. Nhóm sản phẩm, giỏ hàng, đơn hàng

### Mục đích

Phục vụ shop thú cưng: thực phẩm, đồ dùng, xem sản phẩm, tìm kiếm/lọc, thêm giỏ hàng, đặt mua, thanh toán COD/online.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `product_categories` | Danh mục sản phẩm: thức ăn, đồ dùng,... | Bắt buộc |
| `products` | Sản phẩm, giá, mô tả, tồn kho | Bắt buộc |
| `product_images` | Nhiều ảnh cho sản phẩm | Nên có |
| `product_inventory_logs` | Lịch sử nhập/xuất kho | Có thể giản lược |
| `carts` | Giỏ hàng hiện tại của user | Bắt buộc nếu có cart |
| `cart_items` | Sản phẩm trong giỏ hàng | Bắt buộc |
| `orders` | Đơn hàng | Bắt buộc |
| `order_items` | Chi tiết sản phẩm trong đơn hàng | Bắt buộc |
| `order_status_histories` | Lịch sử trạng thái đơn hàng | Nên có |

### Gợi ý trường chính

#### `products`

- `id`
- `category_id`
- `name`
- `slug`
- `description`
- `price`
- `sale_price`
- `stock_quantity`
- `sku`
- `image_url`
- `average_rating`
- `status`: `active`, `inactive`, `out_of_stock`

#### `orders`

- `id`
- `order_code`
- `user_id`
- `shipping_full_name`
- `shipping_phone`
- `shipping_address`
- `payment_method`
- `payment_status`: `unpaid`, `pending`, `paid`, `failed`, `refunded`
- `order_status`: `pending`, `processing`, `shipping`, `completed`, `cancelled`
- `subtotal_amount`
- `voucher_discount_amount`
- `point_discount_amount`
- `shipping_fee`
- `total_amount`
- `note`
- `created_at`, `updated_at`

### Ràng buộc quan trọng

- Chỉ hiển thị sản phẩm đang kinh doanh.
- Số lượng trong giỏ không được vượt quá tồn kho.
- Khi đặt hàng thành công, đơn hàng mặc định trạng thái `Chờ xử lý`.
- Hỗ trợ COD và thanh toán online.
- Cần lưu số điện thoại và địa chỉ giao hàng tại thời điểm đặt, không chỉ tham chiếu địa chỉ user, để tránh mất lịch sử khi user đổi địa chỉ sau này.

---

## 4.7. Nhóm bệnh án, đơn thuốc, nhật ký sức khỏe

### Mục đích

Lưu hồ sơ y tế chính thức do bác sĩ tạo/cập nhật, đơn thuốc, ghi chú điều trị, và nhật ký sức khỏe cá nhân do chủ thú cưng ghi hằng ngày.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `medical_records` | Hồ sơ bệnh án chính thức của thú cưng | Bắt buộc |
| `medical_record_attachments` | File đính kèm bệnh án | Nên có |
| `prescriptions` | Đơn thuốc gắn với bệnh án | Nên có |
| `prescription_items` | Thuốc trong đơn | Nên có |
| `health_diaries` | Nhật ký theo dõi sức khỏe do chủ thú cưng tạo | Bắt buộc |
| `health_diary_images` | Ảnh trong nhật ký sức khỏe | Nên có |

### Gợi ý trường chính

#### `medical_records`

- `id`
- `pet_id`
- `appointment_id`, nullable
- `online_consultation_id`, nullable
- `doctor_id`
- `diagnosis`
- `symptoms`
- `treatment_plan`
- `doctor_note`
- `record_date`
- `is_official`
- `created_at`, `updated_at`

#### `health_diaries`

- `id`
- `pet_id`
- `user_id`
- `diary_date`
- `eating_status`
- `symptom_note`
- `health_note`
- `mood_note`
- `weight_kg`
- `created_at`, `updated_at`, `deleted_at`

### Ràng buộc quan trọng

- Người dùng có quyền thêm/sửa/xóa nhật ký cá nhân của chính mình.
- Người dùng chỉ được xem/tải bệnh án, không được sửa hoặc xóa bệnh án do bác sĩ tạo.
- Nếu ngày có bệnh án, lịch nhật ký phải hiển thị liên kết/thẻ bệnh án.
- Có thể dùng unique `(pet_id, user_id, diary_date)` nếu mỗi user chỉ có một nhật ký cho mỗi thú cưng trong một ngày.

---

## 4.8. Nhóm nhắc lịch tiêm phòng và chăm sóc

### Mục đích

Lưu lịch nhắc tiêm phòng, tẩy giun, khám định kỳ và các lịch chăm sóc khác.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `pet_reminders` | Lịch nhắc cho từng thú cưng | Bắt buộc |
| `pet_care_histories` | Ghi nhận đã thực hiện lịch chăm sóc | Nên có |
| `notification_logs` | Log gửi email/in-app nếu muốn theo dõi lỗi | Nên có |

### Gợi ý trường chính

#### `pet_reminders`

- `id`
- `pet_id`
- `user_id`
- `reminder_type`: `vaccination`, `deworming`, `routine_checkup`, `other`
- `title`
- `reminder_date`
- `remind_before_days`: 1, 3, 5, 7
- `note`
- `status`: `pending`, `completed`, `cancelled`
- `completed_at`
- `next_suggested_date`

### Ràng buộc quan trọng

- Ngày nhắc phải là ngày tương lai khi tạo mới.
- Mặc định nhắc trước 3 ngày.
- Có thể tùy chỉnh 1, 3, 5 hoặc 7 ngày.
- Khi đánh dấu hoàn thành, ghi nhận vào lịch sử chăm sóc.

---

## 4.9. Nhóm tìm kiếm và lọc

### Mục đích

Hỗ trợ tìm kiếm/lọc sản phẩm, dịch vụ, lịch sử đặt lịch, bài viết, nhận nuôi, cẩm nang sơ cứu.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `search_logs` | Lưu lịch sử từ khóa tìm kiếm của user đăng nhập | Có thể có |
| `popular_keywords` | Từ khóa phổ biến/gợi ý | Có thể giản lược |

### Gợi ý trường chính

#### `search_logs`

- `id`
- `user_id`, nullable nếu khách vãng lai
- `keyword`
- `search_type`: `product`, `appointment`, `service`, `post`, `adoption`, `first_aid`, `global`
- `filters_json`
- `created_at`

### Ràng buộc quan trọng

- Khách vãng lai vẫn có thể tìm kiếm, nhưng không cần lưu lịch sử.
- User đã đăng nhập có thể lưu từ khóa gần đây.
- Fuzzy search thường xử lý ở tầng code hoặc search engine; database có thể hỗ trợ bằng index/fulltext.

---

## 4.10. Nhóm blog, bài viết cộng đồng, cẩm nang sơ cứu

### Mục đích

Phục vụ blog nền tảng do admin đăng, cộng đồng chia sẻ do user đăng, và cẩm nang sơ cứu có nội dung dạng bước, ảnh, video.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `post_categories` | Danh mục bài viết | Bắt buộc |
| `posts` | Blog nền tảng, bài cộng đồng, bài cứu trợ nếu muốn dùng chung | Bắt buộc |
| `post_images` | Ảnh bài viết | Nên có |
| `post_comments` | Bình luận/thảo luận cộng đồng | Có thể có |
| `first_aid_guides` | Cẩm nang sơ cứu dạng có cấu trúc | Nên tách riêng |
| `first_aid_steps` | Các bước sơ cứu | Nên có |
| `first_aid_media` | Ảnh/video minh họa sơ cứu | Nên có |
| `first_aid_symptoms` | Triệu chứng/tình huống để lọc | Nên có |

### Gợi ý trường chính

#### `posts`

- `id`
- `category_id`
- `author_id`
- `post_type`: `platform_blog`, `community`, `rescue`, `news`
- `title`
- `slug`
- `summary`
- `content`
- `thumbnail_url`
- `status`: `draft`, `published`, `hidden`, `pending`, `rejected`
- `published_at`
- `created_at`, `updated_at`, `deleted_at`

#### `first_aid_guides`

- `id`
- `title`
- `situation_description`
- `emergency_phone`
- `video_url`
- `status`: `active`, `inactive`
- `created_by`
- `updated_by`

### Ràng buộc quan trọng

- Blog nền tảng chỉ admin được đăng.
- Bài cộng đồng: user đăng nhập được đăng, sửa, xóa bài của chính mình.
- Cẩm nang sơ cứu chỉ admin tạo/sửa/xóa.
- Cẩm nang sơ cứu phải có tiêu đề, mô tả tình huống, tối thiểu 3 bước sơ cứu.
- Video sơ cứu MP4/WebM, tối đa 250MB theo đặc tả.
- Ảnh minh họa sơ cứu JPG/PNG, tối đa 5MB mỗi ảnh.

---

## 4.11. Nhóm cứu trợ động vật

### Mục đích

Hiển thị thông tin cứu trợ, trạm cứu trợ, chiến dịch, liên kết quyên góp, fanpage, số điện thoại.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `rescue_organizations` | Tổ chức/trạm cứu trợ | Nên có |
| `rescue_posts` | Bài viết/chiến dịch cứu trợ | Bắt buộc nếu không dùng chung `posts` |
| `rescue_links` | Link ngoài: quyên góp, fanpage, website | Nên có |

### Gợi ý trường chính

#### `rescue_organizations`

- `id`
- `name`
- `phone_number`
- `email`
- `address`
- `description`
- `fanpage_url`
- `donation_url`
- `status`

#### `rescue_posts`

- `id`
- `organization_id`
- `title`
- `content`
- `thumbnail_url`
- `status`: `active`, `inactive`, `closed`
- `created_by`
- `created_at`

### Ràng buộc quan trọng

- Khách vãng lai vẫn xem được cứu trợ.
- Link ngoài cần minh bạch.
- Nếu không có chiến dịch, hiển thị thông báo chưa có thông tin mới.

---

## 4.12. Nhóm nhận nuôi thú cưng

### Mục đích

Admin đăng thú cưng cần nhận nuôi; user xem danh sách, lọc, gửi đơn; admin duyệt/từ chối; user theo dõi trạng thái đơn.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `adoption_pets` | Thú cưng cần nhận nuôi | Bắt buộc |
| `adoption_pet_images` | Ảnh thú cưng nhận nuôi | Bắt buộc |
| `adoption_requests` | Đơn xin nhận nuôi | Bắt buộc |
| `adoption_request_status_histories` | Lịch sử duyệt/từ chối đơn | Nên có |

### Gợi ý trường chính

#### `adoption_pets`

- `id`
- `posted_by`
- `name`
- `species_id`
- `breed_id`
- `age_text`
- `gender`
- `region`
- `personality_description`
- `health_status`
- `adoption_conditions`
- `status`: `available`, `adopted`, `closed`, `hidden`
- `created_at`, `updated_at`

#### `adoption_requests`

- `id`
- `adoption_pet_id`
- `user_id`
- `full_name`
- `phone_number`
- `address`
- `reason`
- `housing_condition`
- `experience`
- `status`: `pending`, `approved`, `rejected`, `cancelled`
- `reviewed_by`
- `reviewed_at`
- `rejection_reason`

### Ràng buộc quan trọng

- Khách không cần đăng nhập để xem danh sách nhận nuôi.
- Muốn gửi đơn phải đăng nhập.
- Mỗi user chỉ được có 1 đơn đang chờ duyệt cho cùng một thú cưng.
- Mỗi user tối đa 3 đơn nhận nuôi đang ở trạng thái `pending`.
- Mỗi bài đăng thú cưng nhận nuôi có tối thiểu 1 ảnh, tối đa 5 ảnh.
- Ảnh nhận nuôi JPG/JPEG/PNG, tối đa 10MB mỗi ảnh.
- Admin phải duyệt trong 7 ngày làm việc; hệ thống nên có nhắc admin.

---

## 4.13. Nhóm tư vấn AI

### Mục đích

Lưu phiên chat AI, tin nhắn user/AI, disclaimer, triệu chứng khẩn cấp, lịch sử xem lại trong 30 ngày.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `ai_chat_sessions` | Phiên tư vấn AI | Bắt buộc nếu lưu lịch sử |
| `ai_chat_messages` | Tin nhắn trong phiên | Bắt buộc nếu lưu lịch sử |

### Gợi ý trường chính

#### `ai_chat_sessions`

- `id`
- `user_id`
- `pet_id`, nullable nếu nhập thông tin thú cưng tự do
- `ad_hoc_pet_info`
- `started_at`
- `ended_at`
- `expires_at`
- `disclaimer_accepted`
- `status`: `active`, `ended`, `expired`

#### `ai_chat_messages`

- `id`
- `session_id`
- `sender_type`: `user`, `ai`, `system`
- `message_text`
- `is_emergency_detected`
- `created_at`

### Ràng buộc quan trọng

- Mỗi tin nhắn user tối đa 1000 ký tự.
- AI chỉ tư vấn tham khảo, không thay thế bác sĩ.
- AI không được chẩn đoán chắc chắn hoặc kê đơn thuốc.
- Nội dung AI không được ghi vào hồ sơ bệnh án chính thức.
- Lịch sử chat lưu 30 ngày.
- Chỉ chủ tài khoản mới xem được lịch sử chat của mình.

---

## 4.14. Nhóm tư vấn online với bác sĩ qua chat/video

### Mục đích

User đặt lịch tư vấn online với bác sĩ, gửi mô tả triệu chứng và ảnh/video, bác sĩ xác nhận/từ chối, tạo phòng chat/video, lưu tin nhắn/file/ghi chú vào hồ sơ y tế.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `online_consultations` | Lịch tư vấn online | Bắt buộc |
| `consultation_attachments` | Ảnh/video triệu chứng user gửi | Bắt buộc nếu có upload |
| `consultation_rooms` | Phòng chat/video riêng | Bắt buộc nếu có chat/video |
| `consultation_messages` | Tin nhắn giữa user và bác sĩ | Bắt buộc nếu có chat |
| `consultation_notes` | Ghi chú y khoa của bác sĩ sau phiên | Nên có |

### Gợi ý trường chính

#### `online_consultations`

- `id`
- `consultation_code`
- `customer_id`
- `pet_id`
- `doctor_id`
- `time_slot_id`
- `scheduled_date`
- `start_time`
- `end_time`
- `symptom_description`
- `status`: `pending`, `confirmed`, `rejected`, `cancelled`, `missed`, `completed`
- `rejection_reason`
- `doctor_note`
- `created_at`, `updated_at`

#### `consultation_rooms`

- `id`
- `online_consultation_id`
- `room_code`
- `room_type`: `chat`, `video`, `chat_video`
- `open_at`
- `closed_at`
- `status`: `waiting`, `open`, `closed`, `expired`

#### `consultation_messages`

- `id`
- `room_id`
- `sender_id`
- `message_type`: `text`, `image`, `video`, `file`
- `message_text`
- `file_url`
- `created_at`

### Ràng buộc quan trọng

- Lịch online ban đầu ở trạng thái `Chờ xác nhận`.
- Bác sĩ có quyền xác nhận hoặc từ chối, nếu từ chối phải nhập lý do.
- Sau khi xác nhận, hệ thống tạo room riêng.
- Room chỉ mở trước giờ hẹn tối đa 5 phút.
- Nếu quá 15 phút từ giờ bắt đầu mà một trong hai bên không tham gia, chuyển trạng thái `missed`.
- Sau khi bác sĩ hoàn thành, room bị khóa.
- Ảnh đính kèm JPG/JPEG/PNG tối đa 10MB/tệp.
- Video tối đa 50MB.
- Tin nhắn, file và ghi chú bác sĩ cần liên kết về hồ sơ y tế của thú cưng.

---

## 4.15. Nhóm đánh giá và phản hồi

### Mục đích

User đánh giá sau khi hoàn thành dịch vụ hoặc đơn hàng; admin kiểm duyệt; đánh giá được duyệt mới hiển thị công khai; cập nhật điểm trung bình cho dịch vụ hoặc bác sĩ.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `reviews` | Đánh giá sao và bình luận | Bắt buộc |
| `review_moderation_logs` | Lịch sử admin duyệt/từ chối/xóa mềm | Nên có |

### Gợi ý trường chính

#### `reviews`

- `id`
- `user_id`
- `appointment_id`, nullable
- `order_id`, nullable
- `service_id`, nullable
- `doctor_id`, nullable
- `product_id`, nullable
- `rating`: 1 đến 5
- `comment`
- `status`: `pending`, `approved`, `rejected`, `deleted`
- `moderated_by`
- `moderated_at`
- `rejection_reason`
- `created_at`, `updated_at`, `deleted_at`

### Ràng buộc quan trọng

- Chỉ được đánh giá khi dịch vụ/đơn hàng đã hoàn thành.
- Bắt buộc chọn số sao từ 1 đến 5.
- Đánh giá mới gửi mặc định `pending`.
- Chỉ đánh giá `approved` mới hiển thị công khai.
- Khi đánh giá được duyệt, cập nhật `average_rating` của bác sĩ/dịch vụ/sản phẩm nếu có.

---

## 4.16. Nhóm voucher và khuyến mãi

### Mục đích

Cho phép user nhập mã giảm giá khi thanh toán dịch vụ hoặc đơn hàng; hỗ trợ mã phần trăm hoặc giảm tiền cố định; kiểm tra hạn dùng/lượt dùng/điều kiện tối thiểu.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `vouchers` | Mã giảm giá | Bắt buộc |
| `voucher_usages` | Lịch sử user dùng voucher | Bắt buộc |
| `voucher_targets` | Giới hạn voucher theo sản phẩm/dịch vụ nếu cần | Có thể giản lược |

### Gợi ý trường chính

#### `vouchers`

- `id`
- `code`
- `name`
- `description`
- `discount_type`: `percent`, `fixed`
- `discount_value`
- `max_discount_amount`
- `min_order_amount`
- `usage_limit`
- `used_count`
- `usage_limit_per_user`
- `start_at`
- `end_at`
- `status`: `active`, `inactive`, `expired`

#### `voucher_usages`

- `id`
- `voucher_id`
- `user_id`
- `order_id`, nullable
- `appointment_id`, nullable
- `payment_id`, nullable
- `discount_amount`
- `used_at`

### Ràng buộc quan trọng

- Mã voucher không phân biệt chữ hoa/thường.
- Mỗi hóa đơn/đơn hàng/lịch thanh toán chỉ được dùng tối đa 1 voucher.
- Voucher phải tồn tại, còn hạn, còn lượt dùng.
- Nếu chưa đạt giá trị tối thiểu thì không áp dụng.
- Chỉ trừ lượt dùng sau khi thanh toán thành công.

---

## 4.17. Nhóm tích điểm khách hàng thân thiết

### Mục đích

Tự động cộng điểm sau thanh toán thành công; cho phép dùng điểm để giảm giá ở checkout.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `loyalty_accounts` | Tổng điểm hiện có của user | Nên có |
| `loyalty_point_transactions` | Lịch sử cộng/trừ điểm | Bắt buộc |

### Gợi ý trường chính

#### `loyalty_accounts`

- `id`
- `user_id`
- `current_points`
- `lifetime_earned_points`
- `lifetime_spent_points`
- `updated_at`

#### `loyalty_point_transactions`

- `id`
- `user_id`
- `payment_id`, nullable
- `order_id`, nullable
- `appointment_id`, nullable
- `transaction_type`: `earn`, `redeem`, `refund`, `adjust`
- `points`
- `money_value`
- `description`
- `created_at`

### Ràng buộc quan trọng

- Ví dụ quy đổi: 1 điểm = 1.000 VNĐ.
- Ví dụ tích điểm: 1 điểm cho mỗi 100.000 VNĐ thực trả.
- Điểm cộng mới tính trên số tiền thực trả sau khi trừ voucher/điểm.
- Không được dùng quá số điểm hiện có.
- Nếu giá trị điểm lớn hơn tổng tiền, giới hạn số điểm để tổng thanh toán không âm.

---

## 4.18. Nhóm thông báo

### Mục đích

Dùng chung cho OTP, đặt lịch, hủy/đổi lịch, nhắc tiêm phòng, đơn hàng, nhận nuôi, tư vấn online, thanh toán.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `notifications` | Thông báo gửi cho user/bác sĩ/admin | Bắt buộc |
| `notification_logs` | Log gửi email/SMS/in-app | Nên có |

### Gợi ý trường chính

#### `notifications`

- `id`
- `user_id`
- `title`
- `message`
- `notification_type`: `appointment`, `order`, `payment`, `reminder`, `adoption`, `consultation`, `system`
- `channel`: `in_app`, `email`, `sms`
- `is_read`
- `read_at`
- `related_type`
- `related_id`
- `created_at`

### Ràng buộc quan trọng

- Hệ thống cần gửi thông báo cho user, bác sĩ, admin tùy nghiệp vụ.
- Nếu email lỗi, vẫn nên lưu log và vẫn gửi in-app nếu có.

---

## 4.19. Nhóm liên hệ, giới thiệu, cấu hình hệ thống

### Mục đích

Phục vụ trang Liên hệ, Về chúng tôi, hotline, cấu hình chung của website.

### Bảng đề xuất

| Bảng | Mục đích | Mức độ |
|---|---|---|
| `contact_messages` | Tin nhắn người dùng gửi từ form liên hệ | Nên có |
| `site_settings` | Cấu hình website: hotline, email, địa chỉ, social links | Có thể có |
| `banners` | Banner trang chủ nếu cần | Có thể có |

### Gợi ý trường chính

#### `contact_messages`

- `id`
- `full_name`
- `email`
- `phone_number`
- `subject`
- `message`
- `status`: `new`, `read`, `replied`, `closed`
- `created_at`

---

## 5. Danh sách bảng tổng thể đề xuất

Dưới đây là danh sách bảng đề xuất cho bản database đầy đủ mức trung bình - chi tiết.

### 5.1. Bảng lõi nên có

```text
roles
users
user_profiles
user_addresses
otp_codes
user_sessions
notifications

pet_species
pet_breeds
pets
pet_images
pet_vaccination_histories

branches
specialties
doctors
doctor_specialties
doctor_schedules
time_slots

service_categories
services
service_price_rules
appointments
appointment_services
appointment_status_histories

payments
payment_methods
payment_transactions
refunds
receipts

product_categories
products
product_images
carts
cart_items
orders
order_items
order_status_histories

medical_records
medical_record_attachments
prescriptions
prescription_items
health_diaries
health_diary_images
pet_reminders
pet_care_histories

post_categories
posts
post_images
post_comments
first_aid_guides
first_aid_steps
first_aid_media
first_aid_symptoms

rescue_organizations
rescue_posts
rescue_links
adoption_pets
adoption_pet_images
adoption_requests
adoption_request_status_histories

ai_chat_sessions
ai_chat_messages
online_consultations
consultation_attachments
consultation_rooms
consultation_messages
consultation_notes

reviews
review_moderation_logs
vouchers
voucher_usages
loyalty_accounts
loyalty_point_transactions

search_logs
contact_messages
site_settings
banners
```

### 5.2. Bảng có thể giản lược nếu nhóm muốn database ngắn hơn

Nếu nhóm muốn bản SQL dễ code hơn, có thể bỏ hoặc gộp các bảng sau:

```text
user_profiles
password_reset_logs
payment_transactions
receipts
product_inventory_logs
post_comments
first_aid_symptoms
rescue_links
adoption_request_status_histories
review_moderation_logs
notification_logs
site_settings
banners
```

Tuy nhiên, các bảng liên quan đến user, pet, appointment, product, order, payment, medical record, reminder, AI chat, adoption, review, voucher, loyalty point vẫn nên giữ vì chúng gắn trực tiếp với Use Case.

---

## 6. Quan hệ chính giữa các bảng

### 6.1. User và pet

```text
roles 1 - n users
users 1 - n pets
pet_species 1 - n pets
pet_breeds 1 - n pets
pets 1 - n pet_images
```

### 6.2. User, doctor, appointment

```text
users 1 - 1 doctors
branches 1 - n doctors
specialties n - n doctors thông qua doctor_specialties
doctors 1 - n time_slots
users 1 - n appointments
pets 1 - n appointments
doctors 1 - n appointments
appointments 1 - n appointment_services
appointments 1 - n appointment_status_histories
```

### 6.3. Product, cart, order

```text
product_categories 1 - n products
products 1 - n product_images
users 1 - 1/n carts
carts 1 - n cart_items
products 1 - n cart_items
users 1 - n orders
orders 1 - n order_items
products 1 - n order_items
orders 1 - n order_status_histories
```

### 6.4. Payment, voucher, point

```text
users 1 - n payments
payments có thể liên kết appointment/order/online_consultation
vouchers 1 - n voucher_usages
users 1 - n voucher_usages
users 1 - 1 loyalty_accounts
users 1 - n loyalty_point_transactions
payments 1 - n loyalty_point_transactions
payments 1 - n refunds
```

### 6.5. Medical record, diary, reminder

```text
pets 1 - n medical_records
doctors 1 - n medical_records
appointments 1 - n medical_records
online_consultations 1 - n medical_records
medical_records 1 - n prescriptions
prescriptions 1 - n prescription_items
pets 1 - n health_diaries
pets 1 - n pet_reminders
pet_reminders 1 - n pet_care_histories
```

### 6.6. Content, rescue, adoption

```text
users 1 - n posts
post_categories 1 - n posts
rescue_organizations 1 - n rescue_posts
adoption_pets 1 - n adoption_pet_images
adoption_pets 1 - n adoption_requests
users 1 - n adoption_requests
```

### 6.7. AI và online consultation

```text
users 1 - n ai_chat_sessions
pets 1 - n ai_chat_sessions
ai_chat_sessions 1 - n ai_chat_messages

users/customer 1 - n online_consultations
doctors 1 - n online_consultations
pets 1 - n online_consultations
online_consultations 1 - 1 consultation_rooms
consultation_rooms 1 - n consultation_messages
online_consultations 1 - n consultation_attachments
online_consultations 1 - n consultation_notes
```

---

## 7. Trạng thái nên chuẩn hóa

### 7.1. `users.status`

```text
active
inactive
banned
```

### 7.2. `appointments.status`

```text
pending
confirmed
rescheduled
cancelled
completed
missed
```

### 7.3. `payments.status`

```text
pending
paid
failed
cancelled
refunded
```

### 7.4. `orders.order_status`

```text
pending
processing
shipping
completed
cancelled
```

### 7.5. `orders.payment_status`

```text
unpaid
pending
paid
failed
refunded
```

### 7.6. `adoption_requests.status`

```text
pending
approved
rejected
cancelled
```

### 7.7. `adoption_pets.status`

```text
available
adopted
closed
hidden
```

### 7.8. `reviews.status`

```text
pending
approved
rejected
deleted
```

### 7.9. `pet_reminders.status`

```text
pending
completed
cancelled
```

### 7.10. `online_consultations.status`

```text
pending
confirmed
rejected
cancelled
missed
completed
```

---

## 8. Index và unique constraint nên có

### 8.1. User/auth

```text
UNIQUE users.email
UNIQUE users.phone_number
INDEX users.role_id
INDEX otp_codes.identifier
INDEX otp_codes.expires_at
INDEX user_sessions.user_id
```

### 8.2. Pet

```text
INDEX pets.owner_id
INDEX pets.species_id
INDEX pets.breed_id
```

### 8.3. Appointment/time slot

```text
INDEX appointments.customer_id
INDEX appointments.pet_id
INDEX appointments.doctor_id
INDEX appointments.appointment_date
INDEX appointments.status
UNIQUE appointments.appointment_code
UNIQUE time_slots.doctor_id + time_slots.slot_date + time_slots.start_time + time_slots.end_time
```

### 8.4. Product/order

```text
UNIQUE products.sku
UNIQUE products.slug
INDEX products.category_id
INDEX products.status
INDEX orders.user_id
UNIQUE orders.order_code
INDEX order_items.order_id
INDEX cart_items.cart_id
```

### 8.5. Medical/diary/reminder

```text
INDEX medical_records.pet_id
INDEX medical_records.doctor_id
INDEX medical_records.record_date
UNIQUE health_diaries.pet_id + health_diaries.user_id + health_diaries.diary_date
INDEX pet_reminders.pet_id
INDEX pet_reminders.reminder_date
INDEX pet_reminders.status
```

### 8.6. Voucher/point/review

```text
UNIQUE vouchers.code
INDEX voucher_usages.user_id
INDEX voucher_usages.voucher_id
UNIQUE loyalty_accounts.user_id
INDEX loyalty_point_transactions.user_id
INDEX reviews.status
INDEX reviews.service_id
INDEX reviews.doctor_id
INDEX reviews.product_id
```

### 8.7. Adoption/AI/consultation

```text
INDEX adoption_requests.user_id
INDEX adoption_requests.adoption_pet_id
INDEX adoption_requests.status
INDEX ai_chat_sessions.user_id
INDEX ai_chat_sessions.expires_at
INDEX online_consultations.customer_id
INDEX online_consultations.doctor_id
INDEX online_consultations.status
UNIQUE consultation_rooms.room_code
```

---

## 9. Dữ liệu mẫu nên insert khi tạo SQL

Khi tạo file `.sql`, nên có dữ liệu mẫu để nhóm dễ test giao diện:

### 9.1. Role

```text
admin
customer
doctor
staff
```

### 9.2. User mẫu

```text
1 admin
2 customer
2 doctor
1 staff
```

### 9.3. Pet mẫu

```text
Chó: Poodle, Corgi, Alaska
Mèo: Anh lông ngắn, Ba Tư
```

### 9.4. Dịch vụ mẫu

```text
Khám tổng quát
Tiêm phòng
Khám da liễu
Tẩy giun
Spa tắm sấy
Cắt tỉa lông
Tư vấn online
```

### 9.5. Sản phẩm mẫu

```text
Thức ăn cho chó
Thức ăn cho mèo
Sữa tắm thú cưng
Vòng cổ
Đồ chơi
Lược chải lông
```

### 9.6. Voucher mẫu

```text
PET10: giảm 10%
FREESHIP: giảm tiền cố định
NEWUSER: ưu đãi khách mới
```

### 9.7. Nội dung mẫu

```text
Bài blog nền tảng
Bài cộng đồng
Cẩm nang sơ cứu: ngộ độc, khó thở, chấn thương
Thông tin cứu trợ
Thú cưng cần nhận nuôi
```

---

## 10. Những điểm cần bạn duyệt trước khi tạo SQL

Trước khi tạo file `.sql`, nên xác nhận các điểm này:

### 10.1. Mức độ database

Chọn một trong ba mức:

```text
A. Đơn giản: ít bảng, dễ code, phù hợp demo nhanh.
B. Trung bình: đầy đủ khóa chính/khóa ngoại, đủ tất cả Use Case chính.
C. Chi tiết: nhiều bảng lịch sử/log/trạng thái, gần hệ thống thật hơn.
```

Với scope hiện tại, mình khuyến nghị chọn **B hoặc B+**: đủ Use Case chính nhưng không quá phức tạp.

### 10.2. Thanh toán

Cần xác nhận:

```text
- Thanh toán chỉ mô phỏng hay cần lưu chi tiết giao dịch?
- Có dùng chung bảng payments cho cả đơn hàng, dịch vụ và tư vấn online không?
- Có cần bảng receipts/refunds riêng không?
```

### 10.3. Bác sĩ và nhân viên

Cần xác nhận:

```text
- Bác sĩ có tài khoản đăng nhập riêng không?
- Nhân viên có xác nhận thanh toán tại cửa hàng không?
- Admin có quản lý toàn bộ sản phẩm/dịch vụ/bài viết/nhận nuôi/review không?
```

### 10.4. Online consultation

Cần xác nhận:

```text
- Tư vấn online dùng chung bảng appointments hay tách riêng online_consultations?
- Chat/video chỉ mô phỏng hay cần lưu tin nhắn thật?
```

Khuyến nghị: tách riêng `online_consultations`, nhưng vẫn có thể liên kết về `medical_records`.

### 10.5. Blog và cứu trợ

Cần xác nhận:

```text
- Bài cứu trợ dùng chung bảng posts với post_type = rescue?
- Hay tách riêng rescue_posts?
```

Khuyến nghị: nếu muốn dễ code, dùng riêng `rescue_posts`. Nếu muốn chuẩn hóa nội dung, dùng chung `posts`.

### 10.6. Review

Cần xác nhận đánh giá áp dụng cho:

```text
- Dịch vụ
- Bác sĩ
- Sản phẩm
- Đơn hàng
```

Khuyến nghị: hỗ trợ cả service/doctor/product/order bằng các khóa ngoại nullable trong `reviews`.

---

## 11. Bản đề xuất phạm vi SQL nên tạo

Khi bạn duyệt xong, file `.sql` nên bao gồm:

```text
1. DROP DATABASE IF EXISTS
2. CREATE DATABASE
3. USE database
4. CREATE TABLE đầy đủ
5. PRIMARY KEY
6. FOREIGN KEY
7. UNIQUE / INDEX
8. CHECK cho các status nếu MySQL hỗ trợ
9. INSERT dữ liệu mẫu
10. Một số VIEW hữu ích nếu cần
```

### View có thể tạo thêm

```text
vw_appointment_history
vw_order_summary
vw_pet_medical_timeline
vw_doctor_average_rating
vw_user_loyalty_balance
```

---

## 12. Kết luận đề xuất

Database của hệ thống Pet Clinic nên được thiết kế theo hướng module hóa thành các nhóm lớn:

```text
1. Auth & User
2. Pet Profile
3. Doctor / Branch / Schedule
4. Service & Appointment
5. Payment / Voucher / Loyalty
6. Product / Cart / Order
7. Medical Record / Diary / Reminder
8. Blog / First Aid / Rescue
9. Adoption
10. AI Consultation
11. Online Doctor Consultation
12. Review & Moderation
13. Notification & Contact
```

Bản `.sql` cuối cùng nên ưu tiên **rõ ràng, dễ hiểu, dễ chạy trong MySQL Workbench**, đồng thời đủ quan hệ khóa ngoại để thể hiện đúng nghiệp vụ của đồ án.

