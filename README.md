# Dự án Mô phỏng Hệ thống Phân loại tự động theo Màu sắc các khối hộp trên băng chuyền sử dụng cánh tay UR10
# 1. Mục tiêu
Tự động hóa quá trình phân loại các khối màu (đỏ, xanh, blue) trên băng chuyền.
Kết hợp xử lý hình ảnh, tính toán động học, và điều khiển robot để đạt độ chính xác cao trong môi trường mô phỏng.

# 2. Công cụ và Công nghệ
- **Môi trường mô phỏng:** CoppeliaSim (Vrep)
- **Xử lý hình ảnh:** Xử lý ảnh bằng OpenCV (Python) để phát hiện màu sắc, vị trí và hướng của khối
- **Điều khiển robot:** MATLAB và Robotics Toolbox (Peter Corke) để giải bài toán động học thuận/ngược
- **Phần cứng mô phỏng:** Cánh tay robot UR10, Camera, băng chuyền, và đầu hút BaxterVacuumCup

# 3. Quy trình thực hiện
Algorithms diagram block
![image](https://github.com/user-attachments/assets/b9e5c244-1240-4ef1-834a-0ce0c9d2ec8e)

## Bước 1: Thiết lập mô phỏng trên nền tảng Vrep
- Tạo băng chuyền, khối màu ngẫu nhiên (đỏ, xanh, blue), và giỏ phân loại
- Đặt camera chiến lược để chụp ảnh thời gian thực

## Bước 2: Xử lý ảnh:
- Chuyển đổi ảnh sang không gian màu RGB, áp dũng ngưỡng threshold để phát hiện giới hạn của màu 
- Trích xuất đặc trưng (position, orientation) bằng viền (border)
- Chuyển đổi tọa độ pixel sang tọa độ không gian robot

## Bước 3: Điều khiển robot:
- Sử dụng Inverse Kinematics (IK) để tính toán góc khớp cần thiết 
- Lập kế hoạch quỹ đạo để di chuyển robot mượt hơn, tránh va chạm
- Điều khiển đầu hút (vị trí coi là EF) để nhặt và thả khối vào giỏ tương ứng

## Bước 4: Kiểm thử kết quả và đánh giá hiệu suất
- Độ chính xác phân loại: >= 99% trong môi trường mô phỏng
- Tgian trung bình cho 1 chu kỳ để phân loại xong 1 khối hộp: ~9,6s
- Tổng tgian xử lý 30 khối cubid là ~288.11s

# 4. Kết quả minh họa

![image](https://github.com/user-attachments/assets/db7ca2c0-519d-483d-bfab-d409e9f3bad7)

**Báo cáo chi tiết:** : File .pdf

