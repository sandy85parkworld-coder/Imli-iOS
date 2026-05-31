import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let imliGreen        = Color(hex: "#2E7D32")
    static let imliGreenLight   = Color(hex: "#E8F5E9")
    static let imliGreenMid     = Color(hex: "#A5D6A7")
    static let imliRed          = Color(hex: "#C62828")
    static let imliRedLight     = Color(hex: "#FFEBEE")
    static let imliOrange       = Color(hex: "#E65100")
    static let imliOrangeLight  = Color(hex: "#FFF3E0")
    static let imliAmber        = Color(hex: "#FF8F00")
    static let imliSurface      = Color(hex: "#F2F2F7")
    static let imliCard         = Color.white
    static let imliSeparator    = Color(hex: "#E5E5EA")
    static let imliSecondary    = Color(hex: "#8E8E93")
    static let imliBlue         = Color(hex: "#007AFF")
}

// MARK: - Hex Initialiser
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6: (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8: (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default:(a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB,red:Double(r)/255,green:Double(g)/255,blue:Double(b)/255,opacity:Double(a)/255)
    }
}

// MARK: - Typography
struct ImliFont {
    static func largeTitle()    -> Font { .system(size: 34, weight: .bold, design: .rounded) }
    static func title1()        -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func title2()        -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func title3()        -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
    static func headline()      -> Font { .system(size: 17, weight: .semibold) }
    static func body()          -> Font { .system(size: 17, weight: .regular) }
    static func callout()       -> Font { .system(size: 16, weight: .regular) }
    static func subheadline()   -> Font { .system(size: 15, weight: .regular) }
    static func footnote()      -> Font { .system(size: 13, weight: .regular) }
    static func caption1()      -> Font { .system(size: 12, weight: .regular) }
    static func caption2()      -> Font { .system(size: 11, weight: .regular) }
}

// MARK: - Spacing
struct ImliSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl:CGFloat = 32
}

// MARK: - Corner Radius
struct ImliRadius {
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let pill:CGFloat = 100
}
