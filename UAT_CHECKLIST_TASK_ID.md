# UAT Checklist Theo TASK-ID (BA/Tester)

## Pham vi

- Refresh token flow (Mobile + BE)
- JWT cho Socket Chat/IoT
- Dong bo endpoint Notifications me-flow
- Dong bo endpoint VNPay create-url
- Auction itemType validation

## Moi truong tien de

- BE chay thanh cong va co JWT_SECRET.
- Mobile dang tro dung API_BASE_URL.
- Co san 2 tai khoan user A/B de test chat.
- Co it nhat 1 battery id de test monitor IoT.

## [TASK-001] Login tra ve cap token access + refresh

- Muc tieu nghiep vu: Sau login, he thong phai cap token pair de dam bao session lien tuc.
- Buoc test:
  1. Dang nhap bang tai khoan hop le tren mobile.
  2. Kiem tra response /auth/login co access_token va refresh_token.
  3. Kiem tra token duoc luu trong secure storage (access_token, refresh_token).
- Ket qua mong doi:
  - Co day du access_token + refresh_token.
  - User vao app binh thuong.
- Trang thai: [ ] PASS [ ] FAIL
- Ghi chu loi (neu co):

## [TASK-002] Tu dong refresh khi access token het han

- Muc tieu nghiep vu: Khi access token expired, app tu refresh khong bat user login lai.
- Buoc test:
  1. Dang nhap thanh cong.
  2. Gia lap access token het han (hoac wait theo cau hinh test).
  3. Thuc hien API bao ve (vi du /notifications/me, /dashboard/overview).
  4. Theo doi network: app goi /auth/refresh va retry request cu.
- Ket qua mong doi:
  - Request dau tien 401.
  - App goi /auth/refresh thanh cong.
  - Request duoc retry va thanh cong.
  - Khong bi logout.
- Trang thai: [ ] PASS [ ] FAIL
- Ghi chu loi (neu co):

## [TASK-003] Refresh token khong hop le -> logout an toan

- Muc tieu nghiep vu: Neu refresh token invalid/expired, he thong ket thuc session.
- Buoc test:
  1. Dang nhap.
  2. Sua refresh token trong storage thanh gia tri sai.
  3. Goi API bao ve de kich hoat refresh flow.
- Ket qua mong doi:
  - /auth/refresh that bai.
  - App xoa session va dieu huong ve login/welcome.
- Trang thai: [ ] PASS [ ] FAIL
- Ghi chu loi (neu co):

## [TASK-004] Chat socket bat buoc JWT

- Muc tieu nghiep vu: Khong cho phep ket noi chat bang userId client tu khai.
- Buoc test:
  1. Voi user da login, vao man chat room.
  2. Xac nhan socket connect thanh cong.
  3. Thu ket noi socket khong token (tool debug) hoac token sai.
- Ket qua mong doi:
  - Co token hop le: connect thanh cong.
  - Khong token/token sai: bi disconnect.
- Trang thai: [ ] PASS [ ] FAIL
- Ghi chu loi (neu co):

## [TASK-005] Chat event khong chap nhan sender/user gia mao

- Muc tieu nghiep vu: Server luon lay user identity tu JWT, khong tin payload.
- Buoc test:
  1. Dang nhap user A, gui message tu chat room.
  2. Dung tool debug thu gui sendMessage payload voi senderId = user B.
  3. Thu markAsRead payload voi userId != token user.
- Ket qua mong doi:
  - Sender/user mismatch bi tu choi.
  - Message hop le van gui duoc.
- Trang thai: [ ] PASS [ ] FAIL
- Ghi chu loi (neu co):

## [TASK-006] IoT socket bat buoc JWT

- Muc tieu nghiep vu: Monitor battery qua socket phai co JWT hop le.
- Buoc test:
  1. Vao man battery monitor khi da login.
  2. Kiem tra subscribeBattery thanh cong va nhan telemetry.
  3. Thu ket noi iot socket voi token sai/khong token.
- Ket qua mong doi:
  - Token hop le: subscribe + nhan data.
  - Token sai/khong token: ket noi bi tu choi.
- Trang thai: [ ] PASS [ ] FAIL
- Ghi chu loi (neu co):

## [TASK-007] Notifications su dung me-flow

- Muc tieu nghiep vu: Mobile khong gui userId tu client cho notifications ca nhan.
- Buoc test:
  1. Vao man Notifications.
  2. Kiem tra API goi /notifications/me.
  3. Bam "Doc tat ca" va xac nhan /notifications/me/mark-all-read.
- Ket qua mong doi:
  - Lay danh sach va unread count dung theo user dang login.
  - Khong con goi /notifications/user/:id tren mobile flow ca nhan.
- Trang thai: [ ] PASS [ ] FAIL
- Ghi chu loi (neu co):

## [TASK-008] Tao payment URL VNPay dung endpoint

- Muc tieu nghiep vu: Flow payment hop dong so goi dung endpoint BE.
- Buoc test:
  1. Trong chat contract card, bam nut thanh toan.
  2. Theo doi API request.
- Ket qua mong doi:
  - Goi /payments/vnpay/create-url.
  - Nhan paymentUrl hop le de mo browser.
- Trang thai: [ ] PASS [ ] FAIL
- Ghi chu loi (neu co):

## [TASK-009] Tao auction khong cho itemType ngoai domain

- Muc tieu nghiep vu: Mobile chi gui itemType nam trong domain nghiep vu cho phep.
- Buoc test:
  1. Mo man hinh tao auction.
  2. Kiem tra dropdown itemType.
  3. Tao auction voi cac gia tri hien co.
- Ket qua mong doi:
  - Khong con lua chon OTHER.
  - Tao auction khong bi 400 do itemType invalid.
- Trang thai: [ ] PASS [ ] FAIL
- Ghi chu loi (neu co):

## Tong hop ket qua test

- So case PASS: \_\_\_\_
- So case FAIL: \_\_\_\_
- Blocker can xu ly truoc go-live:
  1.
  2.
