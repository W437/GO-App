import 'package:godelivery_user/features/auth/domain/centralize_login_enum.dart';
import 'package:godelivery_user/features/splash/domain/models/config_model.dart';

class CentralizeLoginHelper {
  static ({CentralizeLoginType type, double size}) getPreferredLoginMethod(CentralizeLoginSetup data, bool isOtpViewEnable, {bool calculateWidth = false}) {
    print('🔍 [HELPER] Evaluating login method...');
    print('   Data: otp=${data.otpLoginStatus}, manual=${data.manualLoginStatus}, social=${data.socialLoginStatus}');
    print('   isOtpViewEnable: $isOtpViewEnable');

    if ((data.otpLoginStatus! && !data.manualLoginStatus! && !data.socialLoginStatus!) || isOtpViewEnable) {
      print('✅ [HELPER] Selected: OTP Only');
      return (type: CentralizeLoginType.otp, size: 400);
    } else if(data.manualLoginStatus! && !data.socialLoginStatus! && !data.otpLoginStatus!) {
      print('✅ [HELPER] Selected: Manual Only');
      return (type: CentralizeLoginType.manual, size: 500);
    } else if(data.socialLoginStatus! && !data.otpLoginStatus! && !data.manualLoginStatus!) {
      print('✅ [HELPER] Selected: Social Only');
      return (type: CentralizeLoginType.social, size: 500);
    } else if(data.manualLoginStatus! && data.socialLoginStatus! && !data.otpLoginStatus!) {
      print('✅ [HELPER] Selected: Manual + Social');
      return (type: CentralizeLoginType.manualAndSocial, size: 700);
    } else if(data.manualLoginStatus! && data.socialLoginStatus! && data.otpLoginStatus!) {
      print('✅ [HELPER] Selected: Manual + Social + OTP');
      return (type: CentralizeLoginType.manualAndSocialAndOtp, size: 700);
    } else if(!data.manualLoginStatus! && data.socialLoginStatus! && data.otpLoginStatus!) {
      print('✅ [HELPER] Selected: OTP + Social');
      return (type: CentralizeLoginType.otpAndSocial, size: 500);
    } else if(data.manualLoginStatus! && !data.socialLoginStatus! && data.otpLoginStatus!) {
      print('✅ [HELPER] Selected: Manual + OTP');
      return (type: CentralizeLoginType.manualAndOtp, size: 700);
    } else {
      print('⚠️ [HELPER] No match - Defaulting to Manual');
      return (type: CentralizeLoginType.manual, size: 500);
    }
  }
}