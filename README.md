# ⏱️ 초음파 센서 + 온습도 센서 + Stopwatch / Watch 시스템

> 초음파 거리 센서(SR04), 온습도 센서(DHT11), Stopwatch/Watch 기능을 FPGA에서 통합 구현하고, 버튼·스위치 기반으로 동작이 전환되는 제어 시스템

![Sensor](https://img.shields.io/badge/Hardware-SR04%20%26%20DHT11-green?style=flat-square)
![Language](https://img.shields.io/badge/Language-Verilog-blue?style=flat-square)
![FPGA](https://img.shields.io/badge/FPGA-Basys3-red?style=flat-square)

---

## 📋 프로젝트 개요

초음파 거리 센서(SR04), 온습도 센서(DHT11), Stopwatch/Watch 기능을 FPGA에서 통합 구현하고, 버튼·스위치 기반으로 동작이 전환되는 제어 시스템입니다.

### 🎯 주요 목표
- SR04 초음파 센서의 Trigger/Echo 타이밍을 FSM으로 구현하고, **Echo 측 기반 거리 로직 설계**
- 거리 측정 신호의 **노이즈를 최소화하도록 타이밍 기준** 정제
- 모든 측정값을 **UART로 송출하도록 시스템 인터페이스** 구성

---

## ✨ 주요 기능

### 1. SR04 초음파 센서
- **SR04 초음파 센서**의 **Trigger/Echo 타이밍**을 **FSM**으로 구현하고, **Echo 측 기반 거리 로직 설계**
- 거리 측정 신호의 **노이즈를 최소화하도록 타이밍 기준** 정제
- 모든 측정값을 **UART로 송출하도록 시스템 인터페이스** 구성

### 2. DHT11 온습도 센서
- **SR04, DHT11 센서가 안정적으로 거리(오차±1cm)를 측정**하고 LCD에 실시간 표시
- **Stopwatch/Watch** 기능이 **버튼 및 pc 입력**에 따라 **정확하게 동작**하며 값이 깨지지 않음
- 거리·온습도·시계·스톱워치 정보가 **UART로 전송되어 외부 모니터링 가능**

### 3. Stopwatch / Watch
- **Stopwatch/Watch** 기능이 **버튼 및 pc 입력**에 따라 **정확하게 동작**하며 값이 깨지지 않음

### 4. UART 모니터링
- 거리·온습도·시계·스톱워치 정보가 **UART로 전송되어 외부 모니터링 가능**

---

## 🏗️ 시스템 아키텍처

### 📊 SR04 신호에 따른 FSM 단계 구성 (START, WAIT, DIST)
```
      ┌─────────┐
      │  START  │  → o_trig = tick_1us X 10
      └────┬────┘
           ▼
      ┌─────────┐
      │  WAIT   │  → 40kHz X 8 = 200us
      └────┬────┘
           ▼
      ┌─────────┐
      │  DIST   │  → o_dist
      └─────────┘
           │
           └─→ usec / 58 = cm
```

### 📊 PC & SR04 & FPGA 동작 결과
![System Operation](./images/system_operation.png)
*(이미지 파일이 있다면 images 폴더에 넣어주세요)*

**SR04: dist=339.9cm**

---

## 🔧 개발 환경

|        항목       | 사양 |
|-------------------|------|
|    **Language**   | Verilog |
|      **Tool**     | Vivado |
|      **FPGA**     | Basys3 (Xilinx) |
|     **Sensors**   | SR04 (초음파), DHT11 (온습도) |
| **Communication** | UART |
|    **Display**    | 7-Segment LED, LCD |

---

## 📈 성능 지표

### ✅ 검증 결과
- **SR04, DHT11 센서가 안정적으로 거리(오차±1cm)를 측정**하고 LCD에 실시간 표시
- **Stopwatch/Watch** 기능이 **버튼 및 pc 입력**에 따라 **정확하게 동작**하며 값이 깨지지 않음
- 거리·온습도·시계·스톱워치 정보가 **UART로 전송되어 외부 모니터링 가능**

### 🐛 Trouble Shooting

#### 문제: SR04 연속 측정 과정에서 Echo 신호 노이즈로 거리 출력 값이 순간적으로 튀며 불안정하게 표시됨
- **해결**: FSM 마지막에 **out_delay 단계를 추가**해 **계산 완료 후 출력 값을 일정 시간 유지**하여 측정·표시 안정화

---

## 📁 프로젝트 구조

```
Sensor-Stopwatch/
├── rtl/                    # RTL 소스 코드
│   ├── sr04_controller.v  # 초음파 센서
│   ├── dht11_controller.v # 온습도 센서
│   ├── stopwatch.v        # 스톱워치
│   ├── watch.v            # 시계
│   ├── uart_tx.v          # UART 송신
│   └── top.v
├── tb/                     # Testbench 파일
├── images/                 # 문서용 이미지
└── README.md
```

---

## 🚀 사용 방법

### 1. FPGA 합성 및 다운로드
```tcl
# Vivado에서
source build.tcl
program_hw_devices
```

### 2. 센서 연결
```
SR04:
- VCC → 5V
- GND → GND
- TRIG → FPGA GPIO
- ECHO → FPGA GPIO

DHT11:
- VCC → 3.3V
- GND → GND
- DATA → FPGA GPIO
```

### 3. UART 모니터링
```bash
# Serial Terminal (9600 baud)
# 거리, 온도, 습도, 시간 정보 수신
```

---

## 📊 센서 사양

### SR04 초음파 센서
- 측정 범위: 2cm ~ 400cm
- 정확도: ±1cm
- Trigger: 10μs pulse
- Echo: 거리에 비례하는 펄스폭

### DHT11 온습도 센서
- 온도 범위: 0°C ~ 50°C (±2°C)
- 습도 범위: 20% ~ 90% RH (±5%)
- 샘플링 주기: 1초
- 통신 프로토콜: Single-bus data format

---

## 📚 참고 자료

- [SR04 Ultrasonic Sensor Datasheet](https://cdn.sparkfun.com/datasheets/Sensors/Proximity/HCSR04.pdf)
- [DHT11 Temperature & Humidity Sensor Datasheet](https://www.mouser.com/datasheet/2/758/DHT11-Technical-Data-Sheet-Translated-Version-1143054.pdf)
- [UART Protocol](https://www.ti.com/lit/ug/sprugp1/sprugp1.pdf)

---

## 👤 Author

**이서영 (Lee Seoyoung)**
- 📧 Email: lsy1922@naver.com
- 🔗 GitHub: [@seoY0206](https://github.com/seoY0206)

---

## 📝 License

This project is for educational purposes.

---

<div align="center">

**⭐ 도움이 되었다면 Star를 눌러주세요! ⭐**

</div>
