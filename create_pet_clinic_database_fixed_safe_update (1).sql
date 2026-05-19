-- =============================================================
-- PET CLINIC DATABASE SCRIPT
-- Version: 1.0
-- Target DBMS: MySQL 8.x / MySQL Workbench
-- Charset: utf8mb4
-- Scope: Medium level database with primary keys, foreign keys,
--        core constraints, indexes, views and sample data.
-- =============================================================

DROP DATABASE IF EXISTS pet_clinic_db;
CREATE DATABASE pet_clinic_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE pet_clinic_db;
SET NAMES utf8mb4;
SET time_zone = '+07:00';

-- =============================================================
-- 1. USERS, ROLES, AUTHENTICATION, NOTIFICATIONS
-- =============================================================

CREATE TABLE roles (
    role_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_code VARCHAR(50) NOT NULL UNIQUE,
    role_name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_id BIGINT UNSIGNED NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    gender ENUM('MALE','FEMALE','OTHER','UNKNOWN') NOT NULL DEFAULT 'UNKNOWN',
    date_of_birth DATE,
    loyalty_points INT NOT NULL DEFAULT 0,
    status ENUM('ACTIVE','INACTIVE','DISABLED') NOT NULL DEFAULT 'ACTIVE',
    email_verified_at DATETIME,
    phone_verified_at DATETIME,
    last_login_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(role_id),
    CONSTRAINT chk_users_contact CHECK (email IS NOT NULL OR phone IS NOT NULL),
    CONSTRAINT chk_users_loyalty_points CHECK (loyalty_points >= 0)
) ENGINE=InnoDB;

CREATE TABLE user_addresses (
    address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    receiver_name VARCHAR(150) NOT NULL,
    receiver_phone VARCHAR(20) NOT NULL,
    province VARCHAR(100),
    district VARCHAR(100),
    ward VARCHAR(100),
    street_address VARCHAR(255) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_addresses_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE otp_codes (
    otp_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    contact_value VARCHAR(150) NOT NULL,
    channel ENUM('EMAIL','PHONE') NOT NULL,
    purpose ENUM('REGISTER','RESET_PASSWORD','VERIFY_CONTACT') NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME,
    failed_attempts INT NOT NULL DEFAULT 0,
    resend_available_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_otp_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT chk_otp_failed_attempts CHECK (failed_attempts >= 0)
) ENGINE=InnoDB;

CREATE TABLE user_sessions (
    session_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    remember_me BOOLEAN NOT NULL DEFAULT FALSE,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    expires_at DATETIME NOT NULL,
    revoked_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE notifications (
    notification_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    channel ENUM('IN_APP','EMAIL','SMS') NOT NULL DEFAULT 'IN_APP',
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT UNSIGNED,
    status ENUM('PENDING','SENT','FAILED','READ') NOT NULL DEFAULT 'PENDING',
    read_at DATETIME,
    sent_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================================
-- 2. BRANCHES, STAFF, DOCTORS, SCHEDULES
-- =============================================================

CREATE TABLE branches (
    branch_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    branch_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(150),
    address VARCHAR(255) NOT NULL,
    opening_hours VARCHAR(255),
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE specialties (
    specialty_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    specialty_name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE staff_profiles (
    staff_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    branch_id BIGINT UNSIGNED,
    position_title VARCHAR(120),
    can_confirm_store_payment BOOLEAN NOT NULL DEFAULT TRUE,
    hire_date DATE,
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_staff_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_staff_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE doctors (
    doctor_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    branch_id BIGINT UNSIGNED,
    license_no VARCHAR(100) UNIQUE,
    bio TEXT,
    years_experience INT NOT NULL DEFAULT 0,
    consultation_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
    average_rating DECIMAL(3,2) NOT NULL DEFAULT 0,
    rating_count INT NOT NULL DEFAULT 0,
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_doctors_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_doctors_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE SET NULL,
    CONSTRAINT chk_doctor_experience CHECK (years_experience >= 0),
    CONSTRAINT chk_doctor_fee CHECK (consultation_fee >= 0),
    CONSTRAINT chk_doctor_rating CHECK (average_rating >= 0 AND average_rating <= 5)
) ENGINE=InnoDB;

CREATE TABLE doctor_specialties (
    doctor_id BIGINT UNSIGNED NOT NULL,
    specialty_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (doctor_id, specialty_id),
    CONSTRAINT fk_doctor_specialties_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    CONSTRAINT fk_doctor_specialties_specialty FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE doctor_schedules (
    schedule_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_id BIGINT UNSIGNED NOT NULL,
    day_of_week TINYINT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    schedule_type ENUM('IN_CLINIC','ONLINE','BOTH') NOT NULL DEFAULT 'BOTH',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_doctor_schedules_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    CONSTRAINT chk_doctor_schedules_day CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_doctor_schedules_time CHECK (start_time < end_time)
) ENGINE=InnoDB;

CREATE TABLE doctor_time_slots (
    slot_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    doctor_id BIGINT UNSIGNED NOT NULL,
    branch_id BIGINT UNSIGNED,
    slot_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_type ENUM('IN_CLINIC','ONLINE') NOT NULL DEFAULT 'IN_CLINIC',
    status ENUM('AVAILABLE','HELD','BOOKED','CANCELLED') NOT NULL DEFAULT 'AVAILABLE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_slots_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    CONSTRAINT fk_slots_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE SET NULL,
    CONSTRAINT chk_slots_time CHECK (start_time < end_time),
    UNIQUE KEY uq_doctor_slot (doctor_id, slot_date, start_time, end_time, slot_type)
) ENGINE=InnoDB;

-- =============================================================
-- 3. PET PROFILES
-- =============================================================

CREATE TABLE pet_species (
    species_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    species_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB;

CREATE TABLE pet_breeds (
    breed_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    species_id BIGINT UNSIGNED NOT NULL,
    breed_name VARCHAR(120) NOT NULL,
    description TEXT,
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_breeds_species FOREIGN KEY (species_id) REFERENCES pet_species(species_id),
    UNIQUE KEY uq_species_breed (species_id, breed_name)
) ENGINE=InnoDB;

CREATE TABLE pets (
    pet_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    owner_id BIGINT UNSIGNED NOT NULL,
    species_id BIGINT UNSIGNED,
    breed_id BIGINT UNSIGNED,
    pet_name VARCHAR(120) NOT NULL,
    gender ENUM('MALE','FEMALE','UNKNOWN') NOT NULL DEFAULT 'UNKNOWN',
    birth_date DATE,
    weight_kg DECIMAL(5,2),
    color VARCHAR(80),
    profile_image_url VARCHAR(500),
    health_note TEXT,
    vaccination_note TEXT,
    status ENUM('ACTIVE','DECEASED','DELETED') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_pets_owner FOREIGN KEY (owner_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_pets_species FOREIGN KEY (species_id) REFERENCES pet_species(species_id) ON DELETE SET NULL,
    CONSTRAINT fk_pets_breed FOREIGN KEY (breed_id) REFERENCES pet_breeds(breed_id) ON DELETE SET NULL,
    CONSTRAINT chk_pets_weight CHECK (weight_kg IS NULL OR weight_kg >= 0)
) ENGINE=InnoDB;

CREATE TABLE pet_images (
    image_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pet_id BIGINT UNSIGNED NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    image_type ENUM('PROFILE','GALLERY','MEDICAL') NOT NULL DEFAULT 'GALLERY',
    file_size_mb DECIMAL(6,2),
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pet_images_pet FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pet_vaccinations (
    vaccination_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pet_id BIGINT UNSIGNED NOT NULL,
    vaccine_name VARCHAR(150) NOT NULL,
    vaccination_date DATE NOT NULL,
    next_due_date DATE,
    note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pet_vaccinations_pet FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================================
-- 4. SERVICES AND APPOINTMENTS
-- =============================================================

CREATE TABLE service_categories (
    category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB;

CREATE TABLE services (
    service_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT UNSIGNED NOT NULL,
    service_name VARCHAR(180) NOT NULL,
    description TEXT,
    base_price DECIMAL(12,2) NOT NULL DEFAULT 0,
    duration_minutes INT NOT NULL DEFAULT 30,
    image_url VARCHAR(500),
    average_rating DECIMAL(3,2) NOT NULL DEFAULT 0,
    rating_count INT NOT NULL DEFAULT 0,
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_services_category FOREIGN KEY (category_id) REFERENCES service_categories(category_id),
    CONSTRAINT chk_services_price CHECK (base_price >= 0),
    CONSTRAINT chk_services_duration CHECK (duration_minutes > 0),
    CONSTRAINT chk_services_rating CHECK (average_rating >= 0 AND average_rating <= 5),
    FULLTEXT KEY ft_services_name_desc (service_name, description)
) ENGINE=InnoDB;

CREATE TABLE service_price_rules (
    rule_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_id BIGINT UNSIGNED NOT NULL,
    rule_name VARCHAR(150) NOT NULL,
    rule_type ENUM('AGE_MONTH','WEIGHT_KG','CUSTOM') NOT NULL DEFAULT 'CUSTOM',
    min_value DECIMAL(10,2),
    max_value DECIMAL(10,2),
    surcharge_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    surcharge_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_price_rules_service FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE,
    CONSTRAINT chk_price_rules_amount CHECK (surcharge_amount >= 0),
    CONSTRAINT chk_price_rules_percent CHECK (surcharge_percent >= 0)
) ENGINE=InnoDB;

CREATE TABLE appointments (
    appointment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    appointment_code VARCHAR(50) NOT NULL UNIQUE,
    customer_id BIGINT UNSIGNED NOT NULL,
    pet_id BIGINT UNSIGNED,
    doctor_id BIGINT UNSIGNED,
    branch_id BIGINT UNSIGNED,
    slot_id BIGINT UNSIGNED,
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    customer_phone VARCHAR(20),
    guest_pet_name VARCHAR(120),
    guest_pet_info VARCHAR(255),
    symptom_description TEXT,
    note TEXT,
    status ENUM('PENDING_PAYMENT','WAITING_CONFIRMATION','CONFIRMED','COMPLETED','CANCELLED','RESCHEDULED','REFUNDED','NO_SHOW') NOT NULL DEFAULT 'WAITING_CONFIRMATION',
    estimated_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    cancellation_reason VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_appointments_customer FOREIGN KEY (customer_id) REFERENCES users(user_id),
    CONSTRAINT fk_appointments_pet FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE SET NULL,
    CONSTRAINT fk_appointments_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE SET NULL,
    CONSTRAINT fk_appointments_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE SET NULL,
    CONSTRAINT fk_appointments_slot FOREIGN KEY (slot_id) REFERENCES doctor_time_slots(slot_id) ON DELETE SET NULL,
    CONSTRAINT chk_appointments_time CHECK (start_time < end_time),
    CONSTRAINT chk_appointments_total CHECK (estimated_total >= 0),
    UNIQUE KEY uq_appointment_slot (slot_id)
) ENGINE=InnoDB;

CREATE TABLE appointment_services (
    appointment_service_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    appointment_id BIGINT UNSIGNED NOT NULL,
    service_id BIGINT UNSIGNED NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(12,2) NOT NULL DEFAULT 0,
    surcharge_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_appointment_services_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    CONSTRAINT fk_appointment_services_service FOREIGN KEY (service_id) REFERENCES services(service_id),
    CONSTRAINT chk_appointment_services_quantity CHECK (quantity > 0),
    CONSTRAINT chk_appointment_services_price CHECK (unit_price >= 0 AND surcharge_amount >= 0 AND subtotal >= 0)
) ENGINE=InnoDB;

CREATE TABLE appointment_status_history (
    history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    appointment_id BIGINT UNSIGNED NOT NULL,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    changed_by BIGINT UNSIGNED,
    reason VARCHAR(255),
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_appointment_history_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    CONSTRAINT fk_appointment_history_user FOREIGN KEY (changed_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =============================================================
-- 5. PRODUCTS, CARTS, ORDERS
-- =============================================================

CREATE TABLE product_categories (
    category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    parent_id BIGINT UNSIGNED,
    category_name VARCHAR(150) NOT NULL,
    description TEXT,
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_product_categories_parent FOREIGN KEY (parent_id) REFERENCES product_categories(category_id) ON DELETE SET NULL,
    UNIQUE KEY uq_product_category_name (category_name)
) ENGINE=InnoDB;

CREATE TABLE products (
    product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT UNSIGNED NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    sku VARCHAR(80) UNIQUE,
    description TEXT,
    price DECIMAL(12,2) NOT NULL DEFAULT 0,
    stock_quantity INT NOT NULL DEFAULT 0,
    unit VARCHAR(50) NOT NULL DEFAULT 'item',
    main_image_url VARCHAR(500),
    average_rating DECIMAL(3,2) NOT NULL DEFAULT 0,
    rating_count INT NOT NULL DEFAULT 0,
    status ENUM('ACTIVE','INACTIVE','OUT_OF_STOCK') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES product_categories(category_id),
    CONSTRAINT chk_products_price CHECK (price >= 0),
    CONSTRAINT chk_products_stock CHECK (stock_quantity >= 0),
    CONSTRAINT chk_products_rating CHECK (average_rating >= 0 AND average_rating <= 5),
    FULLTEXT KEY ft_products_name_desc (product_name, description)
) ENGINE=InnoDB;

CREATE TABLE product_images (
    image_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    alt_text VARCHAR(255),
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_images_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE carts (
    cart_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    status ENUM('ACTIVE','ORDERED','ABANDONED') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_carts_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE cart_items (
    cart_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cart_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cart_items_cart FOREIGN KEY (cart_id) REFERENCES carts(cart_id) ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT chk_cart_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_cart_items_price CHECK (unit_price >= 0),
    UNIQUE KEY uq_cart_product (cart_id, product_id)
) ENGINE=InnoDB;

-- =============================================================
-- 6. VOUCHERS, ONLINE CONSULTATION, ORDERS, PAYMENTS
-- =============================================================

CREATE TABLE vouchers (
    voucher_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    voucher_name VARCHAR(150) NOT NULL,
    description TEXT,
    discount_type ENUM('PERCENT','FIXED') NOT NULL,
    discount_value DECIMAL(12,2) NOT NULL,
    max_discount_amount DECIMAL(12,2),
    min_order_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_usage_limit INT,
    used_count INT NOT NULL DEFAULT 0,
    per_user_limit INT NOT NULL DEFAULT 1,
    valid_from DATETIME NOT NULL,
    valid_to DATETIME NOT NULL,
    status ENUM('ACTIVE','INACTIVE','EXPIRED') NOT NULL DEFAULT 'ACTIVE',
    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vouchers_created_by FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_vouchers_discount CHECK (discount_value >= 0),
    CONSTRAINT chk_vouchers_min_order CHECK (min_order_amount >= 0),
    CONSTRAINT chk_vouchers_used_count CHECK (used_count >= 0),
    CONSTRAINT chk_vouchers_valid_time CHECK (valid_from < valid_to)
) ENGINE=InnoDB;

CREATE TABLE online_consultations (
    consultation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    consultation_code VARCHAR(50) NOT NULL UNIQUE,
    customer_id BIGINT UNSIGNED NOT NULL,
    pet_id BIGINT UNSIGNED,
    doctor_id BIGINT UNSIGNED NOT NULL,
    slot_id BIGINT UNSIGNED,
    scheduled_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    ad_hoc_pet_name VARCHAR(120),
    ad_hoc_pet_info VARCHAR(255),
    symptom_description TEXT NOT NULL,
    doctor_reject_reason VARCHAR(255),
    doctor_notes TEXT,
    fee DECIMAL(12,2) NOT NULL DEFAULT 0,
    status ENUM('PENDING','CONFIRMED','REJECTED','CANCELLED','MISSED','COMPLETED') NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_online_customer FOREIGN KEY (customer_id) REFERENCES users(user_id),
    CONSTRAINT fk_online_pet FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE SET NULL,
    CONSTRAINT fk_online_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    CONSTRAINT fk_online_slot FOREIGN KEY (slot_id) REFERENCES doctor_time_slots(slot_id) ON DELETE SET NULL,
    CONSTRAINT chk_online_time CHECK (start_time < end_time),
    CONSTRAINT chk_online_fee CHECK (fee >= 0),
    UNIQUE KEY uq_online_slot (slot_id)
) ENGINE=InnoDB;

CREATE TABLE online_consultation_attachments (
    attachment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    consultation_id BIGINT UNSIGNED NOT NULL,
    uploaded_by BIGINT UNSIGNED NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    file_type ENUM('IMAGE','VIDEO','DOCUMENT') NOT NULL DEFAULT 'IMAGE',
    mime_type VARCHAR(100),
    file_size_mb DECIMAL(6,2),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_online_attachments_consultation FOREIGN KEY (consultation_id) REFERENCES online_consultations(consultation_id) ON DELETE CASCADE,
    CONSTRAINT fk_online_attachments_user FOREIGN KEY (uploaded_by) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE consultation_rooms (
    room_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    consultation_id BIGINT UNSIGNED NOT NULL UNIQUE,
    room_code VARCHAR(80) NOT NULL UNIQUE,
    room_type ENUM('CHAT','VIDEO','CHAT_VIDEO') NOT NULL DEFAULT 'CHAT_VIDEO',
    access_opens_at DATETIME NOT NULL,
    access_closes_at DATETIME,
    status ENUM('WAITING','OPEN','LOCKED','CLOSED') NOT NULL DEFAULT 'WAITING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_consultation_rooms_consultation FOREIGN KEY (consultation_id) REFERENCES online_consultations(consultation_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE consultation_messages (
    message_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_id BIGINT UNSIGNED NOT NULL,
    sender_id BIGINT UNSIGNED NOT NULL,
    message_type ENUM('TEXT','IMAGE','VIDEO','FILE','SYSTEM') NOT NULL DEFAULT 'TEXT',
    message_text TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_consultation_messages_room FOREIGN KEY (room_id) REFERENCES consultation_rooms(room_id) ON DELETE CASCADE,
    CONSTRAINT fk_consultation_messages_sender FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE consultation_message_attachments (
    attachment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    message_id BIGINT UNSIGNED NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    file_type ENUM('IMAGE','VIDEO','DOCUMENT') NOT NULL DEFAULT 'IMAGE',
    mime_type VARCHAR(100),
    file_size_mb DECIMAL(6,2),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_consult_msg_attachments_message FOREIGN KEY (message_id) REFERENCES consultation_messages(message_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_code VARCHAR(50) NOT NULL UNIQUE,
    customer_id BIGINT UNSIGNED NOT NULL,
    address_id BIGINT UNSIGNED,
    voucher_id BIGINT UNSIGNED,
    receiver_name VARCHAR(150) NOT NULL,
    receiver_phone VARCHAR(20) NOT NULL,
    shipping_address VARCHAR(255) NOT NULL,
    subtotal_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    point_discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    shipping_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    payment_method ENUM('COD','ONLINE') NOT NULL DEFAULT 'COD',
    status ENUM('PENDING','PROCESSING','SHIPPING','COMPLETED','CANCELLED','REFUNDED') NOT NULL DEFAULT 'PENDING',
    note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES users(user_id),
    CONSTRAINT fk_orders_address FOREIGN KEY (address_id) REFERENCES user_addresses(address_id) ON DELETE SET NULL,
    CONSTRAINT fk_orders_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(voucher_id) ON DELETE SET NULL,
    CONSTRAINT chk_orders_amounts CHECK (subtotal_amount >= 0 AND discount_amount >= 0 AND point_discount_amount >= 0 AND shipping_fee >= 0 AND total_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE order_items (
    order_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price CHECK (unit_price >= 0 AND subtotal >= 0)
) ENGINE=InnoDB;

CREATE TABLE order_status_history (
    history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    changed_by BIGINT UNSIGNED,
    reason VARCHAR(255),
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_history_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_history_user FOREIGN KEY (changed_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE payments (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payment_code VARCHAR(50) NOT NULL UNIQUE,
    customer_id BIGINT UNSIGNED NOT NULL,
    appointment_id BIGINT UNSIGNED,
    order_id BIGINT UNSIGNED,
    online_consultation_id BIGINT UNSIGNED,
    voucher_id BIGINT UNSIGNED,
    method ENUM('COD','CASH_AT_CLINIC','BANK_TRANSFER','MOMO','VNPAY','ONLINE_CARD') NOT NULL,
    status ENUM('PENDING','SUCCESS','FAILED','CANCELLED','REFUNDED') NOT NULL DEFAULT 'PENDING',
    subtotal_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    point_discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    transaction_ref VARCHAR(150),
    paid_at DATETIME,
    confirmed_by BIGINT UNSIGNED,
    note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_customer FOREIGN KEY (customer_id) REFERENCES users(user_id),
    CONSTRAINT fk_payments_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL,
    CONSTRAINT fk_payments_online FOREIGN KEY (online_consultation_id) REFERENCES online_consultations(consultation_id) ON DELETE SET NULL,
    CONSTRAINT fk_payments_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(voucher_id) ON DELETE SET NULL,
    CONSTRAINT fk_payments_confirmed_by FOREIGN KEY (confirmed_by) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_payments_amounts CHECK (subtotal_amount >= 0 AND discount_amount >= 0 AND point_discount_amount >= 0 AND total_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE receipts (
    receipt_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT UNSIGNED NOT NULL UNIQUE,
    receipt_code VARCHAR(50) NOT NULL UNIQUE,
    issued_to_name VARCHAR(150) NOT NULL,
    issued_to_contact VARCHAR(150),
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    receipt_url VARCHAR(500),
    issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_receipts_payment FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE,
    CONSTRAINT chk_receipts_total CHECK (total_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE refunds (
    refund_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT UNSIGNED NOT NULL,
    requested_by BIGINT UNSIGNED NOT NULL,
    processed_by BIGINT UNSIGNED,
    refund_code VARCHAR(50) NOT NULL UNIQUE,
    amount DECIMAL(12,2) NOT NULL,
    reason VARCHAR(255) NOT NULL,
    status ENUM('PENDING','APPROVED','REJECTED','COMPLETED') NOT NULL DEFAULT 'PENDING',
    processed_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_refunds_payment FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE,
    CONSTRAINT fk_refunds_requested_by FOREIGN KEY (requested_by) REFERENCES users(user_id),
    CONSTRAINT fk_refunds_processed_by FOREIGN KEY (processed_by) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_refunds_amount CHECK (amount > 0)
) ENGINE=InnoDB;

CREATE TABLE voucher_usages (
    usage_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    voucher_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    payment_id BIGINT UNSIGNED,
    order_id BIGINT UNSIGNED,
    appointment_id BIGINT UNSIGNED,
    online_consultation_id BIGINT UNSIGNED,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    used_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_voucher_usages_voucher FOREIGN KEY (voucher_id) REFERENCES vouchers(voucher_id) ON DELETE CASCADE,
    CONSTRAINT fk_voucher_usages_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_voucher_usages_payment FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE SET NULL,
    CONSTRAINT fk_voucher_usages_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL,
    CONSTRAINT fk_voucher_usages_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    CONSTRAINT fk_voucher_usages_online FOREIGN KEY (online_consultation_id) REFERENCES online_consultations(consultation_id) ON DELETE SET NULL,
    CONSTRAINT chk_voucher_usages_discount CHECK (discount_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE loyalty_point_transactions (
    point_transaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    payment_id BIGINT UNSIGNED,
    transaction_type ENUM('EARN','REDEEM','ADJUST','EXPIRE') NOT NULL,
    points INT NOT NULL,
    conversion_rate_vnd DECIMAL(12,2) NOT NULL DEFAULT 1000,
    amount_equivalent DECIMAL(12,2) NOT NULL DEFAULT 0,
    note VARCHAR(255),
    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_point_transactions_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_point_transactions_payment FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE SET NULL,
    CONSTRAINT fk_point_transactions_created_by FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_point_transactions_rate CHECK (conversion_rate_vnd >= 0),
    CONSTRAINT chk_point_transactions_amount CHECK (amount_equivalent >= 0)
) ENGINE=InnoDB;

-- =============================================================
-- 7. MEDICAL RECORDS, PRESCRIPTIONS, HEALTH DIARIES, REMINDERS
-- =============================================================

CREATE TABLE medical_records (
    medical_record_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pet_id BIGINT UNSIGNED NOT NULL,
    doctor_id BIGINT UNSIGNED NOT NULL,
    appointment_id BIGINT UNSIGNED,
    online_consultation_id BIGINT UNSIGNED,
    record_date DATETIME NOT NULL,
    symptoms TEXT,
    diagnosis TEXT NOT NULL,
    treatment_plan TEXT,
    doctor_note TEXT,
    attachment_url VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_medical_records_pet FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE,
    CONSTRAINT fk_medical_records_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    CONSTRAINT fk_medical_records_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    CONSTRAINT fk_medical_records_online FOREIGN KEY (online_consultation_id) REFERENCES online_consultations(consultation_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE prescriptions (
    prescription_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    medical_record_id BIGINT UNSIGNED NOT NULL,
    prescription_code VARCHAR(50) NOT NULL UNIQUE,
    instruction TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_prescriptions_record FOREIGN KEY (medical_record_id) REFERENCES medical_records(medical_record_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE prescription_items (
    prescription_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    prescription_id BIGINT UNSIGNED NOT NULL,
    medicine_name VARCHAR(180) NOT NULL,
    dosage VARCHAR(120),
    frequency VARCHAR(120),
    duration VARCHAR(120),
    note TEXT,
    CONSTRAINT fk_prescription_items_prescription FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE health_diaries (
    diary_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pet_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    diary_date DATE NOT NULL,
    eating_status VARCHAR(255),
    symptom_note TEXT,
    behavior_note TEXT,
    weight_kg DECIMAL(5,2),
    general_note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_health_diaries_pet FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE,
    CONSTRAINT fk_health_diaries_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT chk_health_diaries_weight CHECK (weight_kg IS NULL OR weight_kg >= 0),
    UNIQUE KEY uq_pet_diary_date (pet_id, user_id, diary_date)
) ENGINE=InnoDB;

CREATE TABLE health_diary_images (
    image_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    diary_id BIGINT UNSIGNED NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_health_diary_images_diary FOREIGN KEY (diary_id) REFERENCES health_diaries(diary_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE care_reminders (
    reminder_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pet_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    reminder_type ENUM('VACCINATION','DEWORMING','ROUTINE_CHECKUP','OTHER') NOT NULL,
    title VARCHAR(180) NOT NULL,
    scheduled_date DATE NOT NULL,
    remind_before_days INT NOT NULL DEFAULT 3,
    note TEXT,
    status ENUM('PENDING','COMPLETED','CANCELLED') NOT NULL DEFAULT 'PENDING',
    completed_at DATETIME,
    next_suggested_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_care_reminders_pet FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE,
    CONSTRAINT fk_care_reminders_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT chk_care_reminders_before CHECK (remind_before_days IN (1,3,5,7))
) ENGINE=InnoDB;

CREATE TABLE care_history (
    care_history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pet_id BIGINT UNSIGNED NOT NULL,
    reminder_id BIGINT UNSIGNED,
    care_type ENUM('VACCINATION','DEWORMING','ROUTINE_CHECKUP','OTHER') NOT NULL,
    care_date DATE NOT NULL,
    note TEXT,
    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_care_history_pet FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE CASCADE,
    CONSTRAINT fk_care_history_reminder FOREIGN KEY (reminder_id) REFERENCES care_reminders(reminder_id) ON DELETE SET NULL,
    CONSTRAINT fk_care_history_created_by FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =============================================================
-- 8. AI CHAT CONSULTATION
-- =============================================================

CREATE TABLE ai_chat_sessions (
    ai_session_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    pet_id BIGINT UNSIGNED,
    ad_hoc_pet_info VARCHAR(255),
    disclaimer_accepted BOOLEAN NOT NULL DEFAULT TRUE,
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at DATETIME,
    expires_at DATETIME,
    status ENUM('ACTIVE','ENDED','EXPIRED') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_ai_sessions_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_ai_sessions_pet FOREIGN KEY (pet_id) REFERENCES pets(pet_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE ai_chat_messages (
    ai_message_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ai_session_id BIGINT UNSIGNED NOT NULL,
    sender_type ENUM('USER','AI','SYSTEM') NOT NULL,
    message_text TEXT NOT NULL,
    is_emergency_flag BOOLEAN NOT NULL DEFAULT FALSE,
    token_count INT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ai_messages_session FOREIGN KEY (ai_session_id) REFERENCES ai_chat_sessions(ai_session_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================================
-- 9. BLOG, COMMUNITY POSTS, FIRST AID GUIDES
-- =============================================================

CREATE TABLE post_categories (
    post_category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB;

CREATE TABLE posts (
    post_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    post_category_id BIGINT UNSIGNED,
    author_id BIGINT UNSIGNED NOT NULL,
    post_type ENUM('PLATFORM_BLOG','COMMUNITY') NOT NULL DEFAULT 'COMMUNITY',
    title VARCHAR(220) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    summary VARCHAR(500),
    content LONGTEXT NOT NULL,
    thumbnail_url VARCHAR(500),
    status ENUM('DRAFT','PUBLISHED','HIDDEN','DELETED') NOT NULL DEFAULT 'PUBLISHED',
    published_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_posts_category FOREIGN KEY (post_category_id) REFERENCES post_categories(post_category_id) ON DELETE SET NULL,
    CONSTRAINT fk_posts_author FOREIGN KEY (author_id) REFERENCES users(user_id),
    FULLTEXT KEY ft_posts_title_content (title, summary, content)
) ENGINE=InnoDB;

CREATE TABLE post_comments (
    comment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    parent_comment_id BIGINT UNSIGNED,
    comment_text TEXT NOT NULL,
    status ENUM('VISIBLE','HIDDEN','DELETED') NOT NULL DEFAULT 'VISIBLE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_post_comments_post FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    CONSTRAINT fk_post_comments_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_post_comments_parent FOREIGN KEY (parent_comment_id) REFERENCES post_comments(comment_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE first_aid_categories (
    first_aid_category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB;

CREATE TABLE first_aid_guides (
    guide_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_aid_category_id BIGINT UNSIGNED,
    created_by BIGINT UNSIGNED NOT NULL,
    title VARCHAR(220) NOT NULL,
    symptom_keywords VARCHAR(500),
    situation_description TEXT NOT NULL,
    emergency_phone VARCHAR(30),
    video_url VARCHAR(500),
    status ENUM('PUBLISHED','DRAFT','HIDDEN') NOT NULL DEFAULT 'PUBLISHED',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_first_aid_guides_category FOREIGN KEY (first_aid_category_id) REFERENCES first_aid_categories(first_aid_category_id) ON DELETE SET NULL,
    CONSTRAINT fk_first_aid_guides_created_by FOREIGN KEY (created_by) REFERENCES users(user_id),
    FULLTEXT KEY ft_first_aid_search (title, symptom_keywords, situation_description)
) ENGINE=InnoDB;

CREATE TABLE first_aid_steps (
    step_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    guide_id BIGINT UNSIGNED NOT NULL,
    step_number INT NOT NULL,
    instruction TEXT NOT NULL,
    image_url VARCHAR(500),
    CONSTRAINT fk_first_aid_steps_guide FOREIGN KEY (guide_id) REFERENCES first_aid_guides(guide_id) ON DELETE CASCADE,
    CONSTRAINT chk_first_aid_steps_number CHECK (step_number > 0),
    UNIQUE KEY uq_guide_step (guide_id, step_number)
) ENGINE=InnoDB;

-- =============================================================
-- 10. RESCUE AND ADOPTION
-- =============================================================

CREATE TABLE rescue_stations (
    station_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    station_name VARCHAR(180) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(150),
    address VARCHAR(255),
    fanpage_url VARCHAR(500),
    donation_url VARCHAR(500),
    status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE rescue_posts (
    rescue_post_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    station_id BIGINT UNSIGNED,
    created_by BIGINT UNSIGNED NOT NULL,
    title VARCHAR(220) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    summary VARCHAR(500),
    content LONGTEXT NOT NULL,
    thumbnail_url VARCHAR(500),
    external_url VARCHAR(500),
    status ENUM('PUBLISHED','DRAFT','HIDDEN') NOT NULL DEFAULT 'PUBLISHED',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_rescue_posts_station FOREIGN KEY (station_id) REFERENCES rescue_stations(station_id) ON DELETE SET NULL,
    CONSTRAINT fk_rescue_posts_created_by FOREIGN KEY (created_by) REFERENCES users(user_id),
    FULLTEXT KEY ft_rescue_posts_search (title, summary, content)
) ENGINE=InnoDB;

CREATE TABLE adoption_pets (
    adoption_pet_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_by BIGINT UNSIGNED NOT NULL,
    species_id BIGINT UNSIGNED,
    pet_name VARCHAR(120) NOT NULL,
    gender ENUM('MALE','FEMALE','UNKNOWN') NOT NULL DEFAULT 'UNKNOWN',
    age_text VARCHAR(80),
    region VARCHAR(150),
    personality TEXT,
    health_status TEXT,
    adoption_conditions TEXT,
    status ENUM('AVAILABLE','ADOPTED','CLOSED') NOT NULL DEFAULT 'AVAILABLE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_adoption_pets_created_by FOREIGN KEY (created_by) REFERENCES users(user_id),
    CONSTRAINT fk_adoption_pets_species FOREIGN KEY (species_id) REFERENCES pet_species(species_id) ON DELETE SET NULL,
    FULLTEXT KEY ft_adoption_pet_search (pet_name, personality, health_status, adoption_conditions)
) ENGINE=InnoDB;

CREATE TABLE adoption_pet_images (
    image_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    adoption_pet_id BIGINT UNSIGNED NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_adoption_images_pet FOREIGN KEY (adoption_pet_id) REFERENCES adoption_pets(adoption_pet_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE adoption_requests (
    request_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    adoption_pet_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    applicant_name VARCHAR(150) NOT NULL,
    applicant_phone VARCHAR(20),
    applicant_address VARCHAR(255) NOT NULL,
    reason TEXT NOT NULL,
    housing_condition TEXT,
    pet_experience TEXT,
    status ENUM('PENDING','APPROVED','REJECTED','CANCELLED') NOT NULL DEFAULT 'PENDING',
    reviewed_by BIGINT UNSIGNED,
    rejection_reason VARCHAR(255),
    reviewed_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_adoption_requests_pet FOREIGN KEY (adoption_pet_id) REFERENCES adoption_pets(adoption_pet_id) ON DELETE CASCADE,
    CONSTRAINT fk_adoption_requests_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_adoption_requests_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =============================================================
-- 11. REVIEWS, CONTACT, SEARCH LOGS
-- =============================================================

CREATE TABLE reviews (
    review_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    target_type ENUM('SERVICE','DOCTOR','PRODUCT') NOT NULL,
    service_id BIGINT UNSIGNED,
    doctor_id BIGINT UNSIGNED,
    product_id BIGINT UNSIGNED,
    appointment_id BIGINT UNSIGNED,
    order_id BIGINT UNSIGNED,
    rating TINYINT NOT NULL,
    comment TEXT,
    status ENUM('PENDING','APPROVED','REJECTED','DELETED') NOT NULL DEFAULT 'PENDING',
    moderated_by BIGINT UNSIGNED,
    moderation_reason VARCHAR(255),
    approved_at DATETIME,
    deleted_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_reviews_service FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE SET NULL,
    CONSTRAINT fk_reviews_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE SET NULL,
    CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE SET NULL,
    CONSTRAINT fk_reviews_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    CONSTRAINT fk_reviews_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL,
    CONSTRAINT fk_reviews_moderated_by FOREIGN KEY (moderated_by) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE contact_messages (
    contact_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150),
    phone VARCHAR(20),
    subject VARCHAR(200),
    message TEXT NOT NULL,
    status ENUM('NEW','PROCESSING','DONE','SPAM') NOT NULL DEFAULT 'NEW',
    handled_by BIGINT UNSIGNED,
    handled_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_contact_handled_by FOREIGN KEY (handled_by) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE search_logs (
    search_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    keyword VARCHAR(255) NOT NULL,
    search_scope ENUM('ALL','PRODUCT','SERVICE','APPOINTMENT_HISTORY','BLOG','FIRST_AID','ADOPTION') NOT NULL DEFAULT 'ALL',
    filters_json JSON,
    result_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_search_logs_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_search_result_count CHECK (result_count >= 0)
) ENGINE=InnoDB;

-- =============================================================
-- 12. INDEXES FOR COMMON QUERIES
-- =============================================================

CREATE INDEX idx_users_role_status ON users(role_id, status);
CREATE INDEX idx_pets_owner_status ON pets(owner_id, status);
CREATE INDEX idx_slots_doctor_date_status ON doctor_time_slots(doctor_id, slot_date, status);
CREATE INDEX idx_appointments_customer_date ON appointments(customer_id, appointment_date);
CREATE INDEX idx_appointments_doctor_date ON appointments(doctor_id, appointment_date);
CREATE INDEX idx_orders_customer_status ON orders(customer_id, status);
CREATE INDEX idx_payments_customer_status ON payments(customer_id, status);
CREATE INDEX idx_health_diaries_pet_date ON health_diaries(pet_id, diary_date);
CREATE INDEX idx_reminders_user_date_status ON care_reminders(user_id, scheduled_date, status);
CREATE INDEX idx_reviews_target_status ON reviews(target_type, status);
CREATE INDEX idx_adoption_requests_user_status ON adoption_requests(user_id, status);
CREATE INDEX idx_notifications_user_status ON notifications(user_id, status);

-- =============================================================
-- 13. VIEWS FOR REPORTING / UI
-- =============================================================

CREATE OR REPLACE VIEW vw_service_average_ratings AS
SELECT
    s.service_id,
    s.service_name,
    COUNT(r.review_id) AS approved_review_count,
    COALESCE(ROUND(AVG(r.rating), 2), 0) AS average_rating
FROM services s
LEFT JOIN reviews r
    ON r.service_id = s.service_id
    AND r.target_type = 'SERVICE'
    AND r.status = 'APPROVED'
GROUP BY s.service_id, s.service_name;

CREATE OR REPLACE VIEW vw_doctor_average_ratings AS
SELECT
    d.doctor_id,
    u.full_name AS doctor_name,
    COUNT(r.review_id) AS approved_review_count,
    COALESCE(ROUND(AVG(r.rating), 2), 0) AS average_rating
FROM doctors d
JOIN users u ON u.user_id = d.user_id
LEFT JOIN reviews r
    ON r.doctor_id = d.doctor_id
    AND r.target_type = 'DOCTOR'
    AND r.status = 'APPROVED'
GROUP BY d.doctor_id, u.full_name;

CREATE OR REPLACE VIEW vw_customer_appointment_history AS
SELECT
    a.appointment_id,
    a.appointment_code,
    a.customer_id,
    u.full_name AS customer_name,
    p.pet_name,
    a.appointment_date,
    a.start_time,
    a.end_time,
    b.branch_name,
    b.address AS branch_address,
    du.full_name AS doctor_name,
    du.phone AS doctor_phone,
    a.status,
    a.estimated_total
FROM appointments a
JOIN users u ON u.user_id = a.customer_id
LEFT JOIN pets p ON p.pet_id = a.pet_id
LEFT JOIN branches b ON b.branch_id = a.branch_id
LEFT JOIN doctors d ON d.doctor_id = a.doctor_id
LEFT JOIN users du ON du.user_id = d.user_id;

-- =============================================================
-- 14. SAMPLE DATA
-- Password hashes below are placeholders for demo only.
-- In a real app, generate hashes by bcrypt/argon2 in backend code.
-- =============================================================

INSERT INTO roles (role_id, role_code, role_name, description) VALUES
(1, 'ADMIN', 'Quản trị viên', 'Quản lý toàn bộ hệ thống'),
(2, 'STAFF', 'Nhân viên', 'Xử lý vận hành, xác nhận thanh toán tại cửa hàng'),
(3, 'DOCTOR', 'Bác sĩ thú y', 'Khám chữa bệnh, tư vấn online, tạo bệnh án'),
(4, 'CUSTOMER', 'Khách hàng', 'Chủ thú cưng sử dụng dịch vụ');

INSERT INTO users (user_id, role_id, full_name, email, phone, password_hash, gender, status, email_verified_at, phone_verified_at, loyalty_points) VALUES
(1, 1, 'Admin Pet Clinic', 'admin@petclinic.local', '0900000001', '$2y$10$demo_admin_hash', 'UNKNOWN', 'ACTIVE', NOW(), NOW(), 0),
(2, 2, 'Nhân viên Thu Ngân', 'staff@petclinic.local', '0900000002', '$2y$10$demo_staff_hash', 'FEMALE', 'ACTIVE', NOW(), NOW(), 0),
(3, 3, 'Bác sĩ Nguyễn An', 'doctor@petclinic.local', '0900000003', '$2y$10$demo_doctor_hash', 'MALE', 'ACTIVE', NOW(), NOW(), 0),
(4, 4, 'Khách hàng Trần Bình', 'customer@petclinic.local', '0900000004', '$2y$10$demo_customer_hash', 'MALE', 'ACTIVE', NOW(), NOW(), 25);

INSERT INTO user_addresses (address_id, user_id, receiver_name, receiver_phone, province, district, ward, street_address, is_default) VALUES
(1, 4, 'Trần Bình', '0900000004', 'TP. Hồ Chí Minh', 'Quận 1', 'Phường Bến Nghé', '123 Nguyễn Huệ', TRUE);

INSERT INTO branches (branch_id, branch_name, phone, email, address, opening_hours, status) VALUES
(1, 'Pet Clinic Trung Tâm', '02800000001', 'central@petclinic.local', '123 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh', '08:00 - 20:00', 'ACTIVE');

INSERT INTO specialties (specialty_id, specialty_name, description) VALUES
(1, 'Khám tổng quát', 'Khám sức khỏe tổng quát cho thú cưng'),
(2, 'Da liễu thú y', 'Điều trị các vấn đề da, lông'),
(3, 'Tư vấn dinh dưỡng', 'Tư vấn chế độ ăn và chăm sóc');

INSERT INTO staff_profiles (staff_id, user_id, branch_id, position_title, can_confirm_store_payment, hire_date) VALUES
(1, 2, 1, 'Thu ngân', TRUE, '2025-01-01');

INSERT INTO doctors (doctor_id, user_id, branch_id, license_no, bio, years_experience, consultation_fee, average_rating, rating_count) VALUES
(1, 3, 1, 'VET-0001', 'Bác sĩ chuyên khám tổng quát và tư vấn sức khỏe thú cưng.', 5, 150000, 0, 0);

INSERT INTO doctor_specialties (doctor_id, specialty_id) VALUES
(1, 1), (1, 3);

INSERT INTO doctor_schedules (doctor_id, day_of_week, start_time, end_time, schedule_type) VALUES
(1, 1, '08:00:00', '12:00:00', 'BOTH'),
(1, 2, '08:00:00', '12:00:00', 'BOTH'),
(1, 3, '13:30:00', '17:30:00', 'BOTH');

INSERT INTO doctor_time_slots (slot_id, doctor_id, branch_id, slot_date, start_time, end_time, slot_type, status) VALUES
(1, 1, 1, '2026-06-01', '09:00:00', '09:30:00', 'IN_CLINIC', 'BOOKED'),
(2, 1, 1, '2026-06-01', '10:00:00', '10:30:00', 'IN_CLINIC', 'AVAILABLE'),
(3, 1, 1, '2026-06-02', '09:00:00', '09:30:00', 'ONLINE', 'BOOKED');

INSERT INTO pet_species (species_id, species_name, description) VALUES
(1, 'Chó', 'Các giống chó cảnh và chó nhà'),
(2, 'Mèo', 'Các giống mèo cảnh và mèo nhà');

INSERT INTO pet_breeds (breed_id, species_id, breed_name) VALUES
(1, 1, 'Poodle'),
(2, 1, 'Corgi'),
(3, 2, 'Mèo Anh lông ngắn');

INSERT INTO pets (pet_id, owner_id, species_id, breed_id, pet_name, gender, birth_date, weight_kg, color, health_note, vaccination_note) VALUES
(1, 4, 1, 1, 'Milu', 'MALE', '2023-05-10', 4.50, 'Nâu', 'Sức khỏe ổn định', 'Đã tiêm mũi cơ bản');

INSERT INTO pet_images (pet_id, image_url, image_type, file_size_mb) VALUES
(1, '/uploads/pets/milu-profile.jpg', 'PROFILE', 1.20);

INSERT INTO pet_vaccinations (pet_id, vaccine_name, vaccination_date, next_due_date, note) VALUES
(1, 'Vaccine 5 bệnh', '2025-05-10', '2026-05-10', 'Tiêm nhắc hằng năm');

INSERT INTO service_categories (category_id, category_name, description) VALUES
(1, 'Khám chữa bệnh', 'Dịch vụ khám và điều trị thú y'),
(2, 'Spa thú cưng', 'Tắm, vệ sinh, cắt tỉa lông');

INSERT INTO services (service_id, category_id, service_name, description, base_price, duration_minutes, status) VALUES
(1, 1, 'Khám tổng quát', 'Khám sức khỏe tổng quát cho chó mèo', 150000, 30, 'ACTIVE'),
(2, 2, 'Tắm spa cơ bản', 'Tắm, sấy và vệ sinh cơ bản', 120000, 45, 'ACTIVE');

INSERT INTO service_price_rules (service_id, rule_name, rule_type, min_value, max_value, surcharge_amount, surcharge_percent) VALUES
(2, 'Phụ phí thú cưng trên 10kg', 'WEIGHT_KG', 10, NULL, 50000, 0);

INSERT INTO appointments (appointment_id, appointment_code, customer_id, pet_id, doctor_id, branch_id, slot_id, appointment_date, start_time, end_time, customer_phone, symptom_description, note, status, estimated_total) VALUES
(1, 'APT-20260601-0001', 4, 1, 1, 1, 1, '2026-06-01', '09:00:00', '09:30:00', '0900000004', 'Kiểm tra sức khỏe định kỳ', 'Khách muốn kiểm tra tổng quát', 'CONFIRMED', 150000);

INSERT INTO appointment_services (appointment_id, service_id, quantity, unit_price, surcharge_amount, subtotal) VALUES
(1, 1, 1, 150000, 0, 150000);

INSERT INTO appointment_status_history (appointment_id, old_status, new_status, changed_by, reason) VALUES
(1, NULL, 'CONFIRMED', 2, 'Nhân viên xác nhận lịch');

INSERT INTO product_categories (category_id, parent_id, category_name, description) VALUES
(1, NULL, 'Thực phẩm', 'Thức ăn cho thú cưng'),
(2, NULL, 'Đồ dùng', 'Phụ kiện và đồ dùng chăm sóc thú cưng');

INSERT INTO products (product_id, category_id, product_name, sku, description, price, stock_quantity, unit, status) VALUES
(1, 1, 'Thức ăn hạt cho chó 1kg', 'FOOD-DOG-001', 'Hạt dinh dưỡng cho chó trưởng thành', 180000, 50, 'gói', 'ACTIVE'),
(2, 2, 'Dây dắt thú cưng', 'ACC-LEASH-001', 'Dây dắt chắc chắn cho chó mèo', 90000, 100, 'cái', 'ACTIVE');

INSERT INTO product_images (product_id, image_url, alt_text, sort_order) VALUES
(1, '/uploads/products/dog-food.jpg', 'Thức ăn hạt cho chó', 1),
(2, '/uploads/products/leash.jpg', 'Dây dắt thú cưng', 1);

INSERT INTO carts (cart_id, user_id, status) VALUES
(1, 4, 'ACTIVE');

INSERT INTO cart_items (cart_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 180000);

INSERT INTO vouchers (voucher_id, code, voucher_name, description, discount_type, discount_value, max_discount_amount, min_order_amount, total_usage_limit, used_count, per_user_limit, valid_from, valid_to, status, created_by) VALUES
(1, 'PET10', 'Giảm 10%', 'Giảm 10% cho đơn hàng/dịch vụ đủ điều kiện', 'PERCENT', 10, 50000, 100000, 100, 0, 1, '2026-01-01 00:00:00', '2026-12-31 23:59:59', 'ACTIVE', 1),
(2, 'FREESHIP', 'Hỗ trợ phí vận chuyển', 'Giảm cố định 30000 VND', 'FIXED', 30000, NULL, 200000, 200, 0, 1, '2026-01-01 00:00:00', '2026-12-31 23:59:59', 'ACTIVE', 1);

INSERT INTO online_consultations (consultation_id, consultation_code, customer_id, pet_id, doctor_id, slot_id, scheduled_date, start_time, end_time, symptom_description, fee, status) VALUES
(1, 'ONL-20260602-0001', 4, 1, 1, 3, '2026-06-02', '09:00:00', '09:30:00', 'Milu hơi biếng ăn, cần tư vấn sơ bộ.', 150000, 'CONFIRMED');

INSERT INTO online_consultation_attachments (consultation_id, uploaded_by, file_url, file_type, mime_type, file_size_mb) VALUES
(1, 4, '/uploads/consultations/milu-symptom.jpg', 'IMAGE', 'image/jpeg', 1.80);

INSERT INTO consultation_rooms (room_id, consultation_id, room_code, room_type, access_opens_at, status) VALUES
(1, 1, 'ROOM-ONL-0001', 'CHAT_VIDEO', '2026-06-02 08:55:00', 'WAITING');

INSERT INTO consultation_messages (room_id, sender_id, message_type, message_text) VALUES
(1, 4, 'TEXT', 'Chào bác sĩ, Milu biếng ăn từ hôm qua.'),
(1, 3, 'TEXT', 'Chào bạn, bạn cho mình biết thêm Milu có nôn hay tiêu chảy không?');

INSERT INTO orders (order_id, order_code, customer_id, address_id, voucher_id, receiver_name, receiver_phone, shipping_address, subtotal_amount, discount_amount, point_discount_amount, shipping_fee, total_amount, payment_method, status, note) VALUES
(1, 'ORD-20260601-0001', 4, 1, 2, 'Trần Bình', '0900000004', '123 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh', 180000, 0, 0, 30000, 210000, 'COD', 'PENDING', 'Giao giờ hành chính');

INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, subtotal) VALUES
(1, 1, 'Thức ăn hạt cho chó 1kg', 1, 180000, 180000);

INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, reason) VALUES
(1, NULL, 'PENDING', 4, 'Khách hàng tạo đơn hàng');

INSERT INTO payments (payment_id, payment_code, customer_id, appointment_id, order_id, online_consultation_id, voucher_id, method, status, subtotal_amount, discount_amount, point_discount_amount, total_amount, transaction_ref, paid_at, confirmed_by, note) VALUES
(1, 'PAY-APT-0001', 4, 1, NULL, NULL, NULL, 'CASH_AT_CLINIC', 'SUCCESS', 150000, 0, 0, 150000, 'CASH-0001', '2026-06-01 09:05:00', 2, 'Nhân viên xác nhận thanh toán tại cửa hàng'),
(2, 'PAY-ORD-0001', 4, NULL, 1, NULL, 2, 'COD', 'PENDING', 210000, 30000, 0, 180000, NULL, NULL, NULL, 'Chờ xử lý COD'),
(3, 'PAY-ONL-0001', 4, NULL, NULL, 1, NULL, 'MOMO', 'SUCCESS', 150000, 0, 0, 150000, 'MOMO-DEMO-0001', '2026-06-01 20:00:00', NULL, 'Thanh toán tư vấn online');

INSERT INTO receipts (payment_id, receipt_code, issued_to_name, issued_to_contact, total_amount, receipt_url) VALUES
(1, 'REC-0001', 'Trần Bình', '0900000004', 150000, '/receipts/rec-0001.pdf'),
(3, 'REC-0002', 'Trần Bình', '0900000004', 150000, '/receipts/rec-0002.pdf');

INSERT INTO voucher_usages (voucher_id, user_id, payment_id, order_id, discount_amount) VALUES
(2, 4, 2, 1, 30000);

INSERT INTO loyalty_point_transactions (user_id, payment_id, transaction_type, points, conversion_rate_vnd, amount_equivalent, note) VALUES
(4, 1, 'EARN', 1, 1000, 1000, 'Cộng điểm sau thanh toán dịch vụ'),
(4, 3, 'EARN', 1, 1000, 1000, 'Cộng điểm sau thanh toán tư vấn online');

INSERT INTO medical_records (medical_record_id, pet_id, doctor_id, appointment_id, online_consultation_id, record_date, symptoms, diagnosis, treatment_plan, doctor_note) VALUES
(1, 1, 1, 1, NULL, '2026-06-01 09:30:00', 'Khám định kỳ', 'Sức khỏe ổn định', 'Theo dõi ăn uống và vận động', 'Tái khám sau 6 tháng nếu không có bất thường'),
(2, 1, 1, NULL, 1, '2026-06-02 09:30:00', 'Biếng ăn nhẹ', 'Chưa đủ cơ sở chẩn đoán bệnh lý nghiêm trọng', 'Theo dõi thêm 24 giờ, đưa đến phòng khám nếu có nôn/tiêu chảy', 'Ghi chú từ phiên tư vấn online');

INSERT INTO prescriptions (prescription_id, medical_record_id, prescription_code, instruction) VALUES
(1, 1, 'PRE-0001', 'Không kê thuốc. Chỉ bổ sung chăm sóc tại nhà.');

INSERT INTO prescription_items (prescription_id, medicine_name, dosage, frequency, duration, note) VALUES
(1, 'Men tiêu hóa thú cưng', 'Theo hướng dẫn sản phẩm', '1 lần/ngày', '3 ngày', 'Chỉ dùng khi cần, hỏi bác sĩ nếu có dấu hiệu nặng');

INSERT INTO health_diaries (diary_id, pet_id, user_id, diary_date, eating_status, symptom_note, behavior_note, weight_kg, general_note) VALUES
(1, 1, 4, '2026-06-01', 'Ăn bình thường', 'Không có biểu hiện bất thường', 'Hoạt động tốt', 4.50, 'Sau khám tổng quát, tình trạng ổn');

INSERT INTO care_reminders (reminder_id, pet_id, user_id, reminder_type, title, scheduled_date, remind_before_days, note, status, next_suggested_date) VALUES
(1, 1, 4, 'VACCINATION', 'Nhắc tiêm vaccine 5 bệnh', '2026-05-10', 3, 'Tiêm nhắc hằng năm', 'PENDING', '2027-05-10');

INSERT INTO ai_chat_sessions (ai_session_id, user_id, pet_id, ad_hoc_pet_info, disclaimer_accepted, expires_at, status) VALUES
(1, 4, 1, NULL, TRUE, '2026-07-01 00:00:00', 'ACTIVE');

INSERT INTO ai_chat_messages (ai_session_id, sender_type, message_text, is_emergency_flag) VALUES
(1, 'SYSTEM', 'AI chỉ hỗ trợ tham khảo, không thay thế bác sĩ thú y.', FALSE),
(1, 'USER', 'Chó của tôi hơi biếng ăn thì cần làm gì?', FALSE),
(1, 'AI', 'Bạn nên theo dõi thêm các dấu hiệu như nôn, tiêu chảy, sốt. Nếu kéo dài hoặc nặng hơn, hãy đặt lịch khám.', FALSE);

INSERT INTO post_categories (post_category_id, category_name, description) VALUES
(1, 'Kiến thức chăm sóc', 'Bài viết chăm sóc thú cưng'),
(2, 'Cộng đồng', 'Chia sẻ trải nghiệm từ người dùng');

INSERT INTO posts (post_id, post_category_id, author_id, post_type, title, slug, summary, content, status, published_at) VALUES
(1, 1, 1, 'PLATFORM_BLOG', 'Cách chăm sóc chó con trong tháng đầu', 'cach-cham-soc-cho-con-trong-thang-dau', 'Hướng dẫn cơ bản cho chủ nuôi mới.', 'Nội dung hướng dẫn chăm sóc chó con...', 'PUBLISHED', NOW()),
(2, 2, 4, 'COMMUNITY', 'Kinh nghiệm chăm Milu sau khi tiêm', 'kinh-nghiem-cham-milu-sau-khi-tiem', 'Chia sẻ từ khách hàng.', 'Milu cần nghỉ ngơi và ăn uống nhẹ nhàng sau khi tiêm.', 'PUBLISHED', NOW());

INSERT INTO post_comments (post_id, user_id, comment_text) VALUES
(2, 4, 'Bài viết chia sẻ kinh nghiệm cá nhân.');

INSERT INTO first_aid_categories (first_aid_category_id, category_name, description) VALUES
(1, 'Ngộ độc', 'Các tình huống nghi ngộ độc'),
(2, 'Khó thở', 'Các tình huống thú cưng khó thở');

INSERT INTO first_aid_guides (guide_id, first_aid_category_id, created_by, title, symptom_keywords, situation_description, emergency_phone, video_url, status) VALUES
(1, 1, 1, 'Sơ cứu khi thú cưng nghi ngộ độc', 'ngộ độc, nôn, co giật', 'Hướng dẫn xử lý ban đầu khi nghi ngộ độc.', '02800000001', NULL, 'PUBLISHED');

INSERT INTO first_aid_steps (guide_id, step_number, instruction, image_url) VALUES
(1, 1, 'Giữ bình tĩnh và đưa thú cưng ra khỏi nguồn nghi gây độc.', NULL),
(1, 2, 'Không tự ý cho uống thuốc hoặc gây nôn nếu chưa có hướng dẫn.', NULL),
(1, 3, 'Liên hệ phòng khám hoặc đưa thú cưng đến cơ sở thú y gần nhất.', NULL);

INSERT INTO rescue_stations (station_id, station_name, phone, email, address, fanpage_url, donation_url, status) VALUES
(1, 'Trạm cứu hộ thú cưng Sài Gòn', '0911111111', 'rescue@petclinic.local', 'TP. Hồ Chí Minh', 'https://example.com/fanpage', 'https://example.com/donate', 'ACTIVE');

INSERT INTO rescue_posts (rescue_post_id, station_id, created_by, title, slug, summary, content, external_url, status) VALUES
(1, 1, 1, 'Chiến dịch hỗ trợ thú cưng bị bỏ rơi', 'chien-dich-ho-tro-thu-cung-bi-bo-roi', 'Kêu gọi hỗ trợ thức ăn và chi phí y tế.', 'Nội dung chiến dịch cứu trợ...', 'https://example.com/rescue-campaign', 'PUBLISHED');

INSERT INTO adoption_pets (adoption_pet_id, created_by, species_id, pet_name, gender, age_text, region, personality, health_status, adoption_conditions, status) VALUES
(1, 1, 2, 'Mimi', 'FEMALE', 'Khoảng 8 tháng', 'TP. Hồ Chí Minh', 'Hiền, thân thiện', 'Đã kiểm tra sức khỏe cơ bản', 'Người nhận cần có kinh nghiệm chăm mèo.', 'AVAILABLE');

INSERT INTO adoption_pet_images (adoption_pet_id, image_url, sort_order) VALUES
(1, '/uploads/adoption/mimi-1.jpg', 1);

INSERT INTO adoption_requests (adoption_pet_id, user_id, applicant_name, applicant_phone, applicant_address, reason, housing_condition, pet_experience, status) VALUES
(1, 4, 'Trần Bình', '0900000004', '123 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh', 'Muốn nhận nuôi và chăm sóc lâu dài', 'Nhà riêng, có không gian trong nhà', 'Đã từng nuôi chó', 'PENDING');

INSERT INTO reviews (review_id, customer_id, target_type, service_id, doctor_id, product_id, appointment_id, order_id, rating, comment, status, moderated_by, moderation_reason, approved_at) VALUES
(1, 4, 'SERVICE', 1, NULL, NULL, 1, NULL, 5, 'Dịch vụ khám nhanh, bác sĩ tư vấn rõ ràng.', 'APPROVED', 1, 'Nội dung hợp lệ', NOW()),
(2, 4, 'DOCTOR', NULL, 1, NULL, 1, NULL, 5, 'Bác sĩ rất tận tâm.', 'APPROVED', 1, 'Nội dung hợp lệ', NOW()),
(3, 4, 'PRODUCT', NULL, NULL, 1, NULL, 1, 4, 'Sản phẩm tốt, giao hàng đúng.', 'PENDING', NULL, NULL, NULL);

INSERT INTO contact_messages (full_name, email, phone, subject, message, status) VALUES
('Nguyễn Khách', 'guest@example.com', '0988888888', 'Hỏi về dịch vụ spa', 'Tôi muốn hỏi lịch spa cho chó nhỏ.', 'NEW');

INSERT INTO search_logs (user_id, keyword, search_scope, filters_json, result_count) VALUES
(4, 'thức ăn cho chó', 'PRODUCT', JSON_OBJECT('category', 'Thực phẩm'), 1),
(NULL, 'sơ cứu ngộ độc', 'FIRST_AID', JSON_OBJECT('category', 'Ngộ độc'), 1);

-- Sync demo average rating values after sample approved reviews.
UPDATE services s
SET average_rating = (
    SELECT COALESCE(ROUND(AVG(r.rating), 2), 0)
    FROM reviews r
    WHERE r.target_type = 'SERVICE'
      AND r.service_id = s.service_id
      AND r.status = 'APPROVED'
),
rating_count = (
    SELECT COUNT(*)
    FROM reviews r
    WHERE r.target_type = 'SERVICE'
      AND r.service_id = s.service_id
      AND r.status = 'APPROVED'
)
WHERE s.service_id > 0;

UPDATE doctors d
SET average_rating = (
    SELECT COALESCE(ROUND(AVG(r.rating), 2), 0)
    FROM reviews r
    WHERE r.target_type = 'DOCTOR'
      AND r.doctor_id = d.doctor_id
      AND r.status = 'APPROVED'
),
rating_count = (
    SELECT COUNT(*)
    FROM reviews r
    WHERE r.target_type = 'DOCTOR'
      AND r.doctor_id = d.doctor_id
      AND r.status = 'APPROVED'
)
WHERE d.doctor_id > 0;

-- =============================================================
-- DONE
-- You can run this file in MySQL Workbench to create pet_clinic_db.
-- =============================================================
