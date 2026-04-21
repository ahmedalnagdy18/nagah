import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nagah/core/colors/app_colors.dart';
import 'package:nagah/core/common/buttons.dart';
import 'package:nagah/core/fonts/app_text.dart';
import 'package:nagah/features/auth/presentation/screens/auth_flow_page.dart';
import 'package:nagah/features/onboarding/widgets/onboarding_model.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  bool revealContent = false;
  bool hideIcon = false;
  int currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openAuthFlow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthFlowPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),
                  if (currentIndex != 4 && currentIndex != 0)
                    Padding(
                      padding: EdgeInsets.only(right: 16).r,
                      child: InkWell(
                        onTap: _openAuthFlow,
                        child: Text(
                          'Skip',
                          style: AppTexts.regular(
                            context,
                          ).copyWith(color: AppColors.orange),
                        ),
                      ),
                    ),
                ],
              ),
              if (currentIndex == 4)
                Text(
                  'Congratulations!',
                  style: AppTexts.heading(context).copyWith(
                    fontSize: 24.sp,
                    color: AppColors.headingLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 32.h),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        onPageChanged: (index) {
                          setState(() {
                            currentIndex = index;
                          });
                        },
                        controller: _pageController,
                        itemCount: onboardingData.length,
                        itemBuilder: (context, index) {
                          final data = onboardingData[index];
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 280.r,
                                  width: 375.r,
                                  child: SvgPicture.asset(
                                    data.image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  data.mainTitle,
                                  style: AppTexts.regular(
                                    context,
                                  ).copyWith(color: AppColors.headingLight),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  data.title,
                                  style: AppTexts.heading(context).copyWith(
                                    fontSize: 20.sp,
                                    color: AppColors.headingLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  data.subTitle,
                                  style: AppTexts.regular(context).copyWith(
                                    color: AppColors.paragraphLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (currentIndex != 0 && currentIndex != 5) ...[
                      SizedBox(height: 16.h),
                      Padding(
                        padding: EdgeInsets.only(bottom: 40.h),
                        child: DotsIndicator(
                          decorator: DotsDecorator(
                            spacing: EdgeInsets.all(4).r,
                            size: Size(6.r, 6.r),
                            activeColor: AppColors.orange,
                            activeSize: Size(8.r, 8.r),
                          ),
                          dotsCount: 4,
                          position: currentIndex.toDouble() - 1,
                        ),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    if (currentIndex == 0 || currentIndex == 4) ...[
                      MainAppButton(
                        backgroundColor: AppColors.orange,
                        bouttonWidth: 196.w,
                        onPressed: () {
                          if (currentIndex == 4) {
                            _openAuthFlow();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        text: currentIndex == 4
                            ? 'Continue to auth'
                            : 'Let\'s get started!',
                        icon: currentIndex == 4
                            ? null
                            : Icon(
                                Icons.arrow_forward_rounded,
                                size: 16.r,
                                color: Colors.white,
                              ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'I already have an account, ',
                            style: AppTexts.regular(context).copyWith(
                              color: AppColors.headingLight.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _openAuthFlow,
                            child: Text(
                              'Login',
                              style: AppTexts.regular(context).copyWith(
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (currentIndex != 0 && currentIndex != 4) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 16).r,
                            child: InkWell(
                              onTap: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Text(
                                'Back',
                                style: AppTexts.regular(context).copyWith(
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ),
                          MaterialButton(
                            padding: EdgeInsetsDirectional.symmetric(
                              vertical: 9.h,
                              horizontal: 9.w,
                            ),
                            minWidth: 0,
                            elevation: 0,
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            color: AppColors.orange,
                            shape: ContinuousRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16.r,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
