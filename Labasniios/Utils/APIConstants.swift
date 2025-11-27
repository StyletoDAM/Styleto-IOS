import Foundation

enum APIConstants {
    static let baseURL = URL(string: "http://10.38.79.164:3000")!

    // AUTH
    static let signupPath = "/auth/signup"
    static let signinPath = "/auth/signin"
    static let googleAuthPath = "/auth/google"
    static let appleAuthPath = "/auth/apple"
    static let verifyEmailPath = "/auth/verify-email"
    static let forgotPasswordPath = "/auth/forgot-password"
    static let verifyOtpPath = "/auth/verify-otp"
    static let resetPasswordPath = "/auth/reset-password"
    
    // CLOTHES
    static let clothMePath = "/cloth/me"
    
    // OUTFITS
    static let outfitsPath = "/outfits"
    static let outfitsMyPath = "/outfits/my"
    static let outfitsGeneratePath = "/outfits/generate"
    
    // STORE
    static let storePath = "/store"
    static let storeMyPath = "/store/my"
    
    // PAYMENT (CORRIGÉ)
    static let testPurchasePath = "/store/test-purchase"
    static let confirmPurchasePath = "/store/purchase"  // + /:id dans l'URL
        
    // HEADERS
    static let jsonContentType = "application/json"
}
