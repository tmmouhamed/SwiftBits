# SwiftBits 🎨

<div align="center">

  <h3>极致的视觉效果集合 | Ultimate Visual Effects Collection</h3>

  <p>从 ReactBits 迁移并使用 SwiftUI + Metal 重新实现的视觉效果库</p>
  <p>Migrated from ReactBits and reimplemented with SwiftUI + Metal</p>

</div>

---

## 👨‍💻 关于作者

<div align="center">

  ### 赵纯想 | Chunxiang Zhao

  **全栈开发工程师 | AI 编程布道者**

  <p>
    <a href="https://chunxiang.space">💻 编程课程</a> •
    <a href="https://chunxiang.ai">🌐 个人主页</a> •
    <a href="https://twitter.com/liseami1">𝕏 @liseami1</a>
  </p>

  <p>
    专注于 AI 辅助编程与独立产品开发<br>
    创办「纯想0基础全栈开发之路」课程，帮助更多人掌握全栈技术<br>
    涵盖移动端、后端、产品设计、自媒体运营等全方位技能
  </p>

  <p>
    <strong>🎓 全栈开发课程优惠</strong><br>
    使用邀请码 <code><strong>AKALOL</strong></code> 享受巨大优惠<br>
    <a href="https://chunxiang.space">立即了解课程详情 →</a>
  </p>

  <p>
    <strong>SwiftBits 项目</strong><br>
    从 <a href="https://github.com/reactbits">ReactBits</a> 迁移并使用 SwiftUI + Metal 重新实现<br>
    将 Web 端的极致视觉效果带入原生 iOS 平台<br>
    展现 GPU 加速渲染的强大性能
  </p>

</div>

---


## 🎬 效果列表

| 效果 | 描述 | 核心技术 |
|------|------|----------|
| **Aurora** 🌌 | 极光效果 | Perlin噪声 + 色彩混合 |
| **Orb** 🔮 | 3D球体渲染 | 光线追踪 + 次表面散射 |
| **Silk** 🌊 | 丝绸织物物理 | 流体动力学模拟 |
| **Dither** 📊 | 抖动波浪效果 | Bayer矩阵 + 波形生成 |
| **Beams** ✨ | 光束动态效果 | 3D噪声 + 金属反射 |
| **Galaxy** 🌟 | 星系粒子系统 | 多层粒子 + HSV色彩 |
| **Prism** 💎 | 棱镜光线折射 | 光线行进 + 色散效果 |
| **Plasma** 🔥 | 等离子波浪 | 复杂数学函数 + 动态扭曲 |
| **Particles** ⚡ | 3D粒子引擎 | 球形分布 + 动态场 |
| **Hyperspeed** 🚀 | 超速隧道 | 透视投影 + 光迹效果 |
| **Diamond** 💠 | 钻石折射 | SDF + 多重反射 |
| **MetallicPaint** 🎨 | 金属漆效果 | PBR渲染 + 噪声纹理 |




## 🛠 技术特性

### 核心技术栈
- **SwiftUI** - 声明式UI框架
- **Metal** - GPU加速图形渲染
- **MetalKit** - Metal渲染管道
- **Combine** - 响应式编程

### 架构特点
```
SwiftBits/
├── Components/          # UI组件
│   ├── DockPanel       # 统一的控制面板
│   └── ASCIICard       # ASCII风格卡片
├── effects/            # 视觉效果
│   └── [EffectName]/
│       ├── *.metal     # Metal着色器
│       ├── *Effect.swift    # 效果实现
│       └── *Demo.swift      # 演示界面
└── ContentView.swift   # 主入口
```

### 安装使用

1. **克隆项目**
```bash
git clone https://github.com/yourusername/SwiftBits.git
cd SwiftBits
```

2. **打开项目**
```bash
open SwiftBits.xcodeproj
```

3. **运行项目**
- 选择目标设备或模拟器
- 按 `Cmd + R` 运行

### 集成到你的项目

每个效果都可以独立使用：

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        // 使用 Aurora 效果
        AuroraEffect(
            amplitude: 1.0,
            blend: 0.5
        )
        .ignoresSafeArea()
    }
}
```

## 📄 开源协议

本项目采用 MIT 协议开源，详见 [LICENSE](LICENSE) 文件。


<div align="center">

  **如果这个项目对你有帮助，请给一个 ⭐️ Star**

  Made with ❤️ by 赵纯想

</div>
