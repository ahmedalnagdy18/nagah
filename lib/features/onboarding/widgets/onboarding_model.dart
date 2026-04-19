class OnboardingModel {
  final String image;
  final String mainTitle;
  final String title;
  final String subTitle;

  OnboardingModel({
    required this.image,
    required this.mainTitle,
    required this.title,
    required this.subTitle,
  });
}

final List<OnboardingModel> onboardingData = [
  OnboardingModel(
    image: 'images/onboarding2.svg',
    mainTitle: 'Welcome',
    title: 'Drive Safer, Smarter',
    subTitle:
        'Discover road conditions and avoid high-risk areas before you start your journey.',
  ),
  OnboardingModel(
    image: 'images/onboarding1.svg',
    mainTitle: 'Road Safety Map',
    title: 'Know the dangers of the roads before you move',
    subTitle:
        'View roads classified by risk level with clear colors to help you choose safer routes.',
  ),
  OnboardingModel(
    image: 'images/onboarding5.svg',
    mainTitle: 'Report Issues',
    title: 'Report any danger',
    subTitle:
        'Easily report accidents or road problems with location and photos to improve road safety.',
  ),
  OnboardingModel(
    image: 'images/onboarding3.svg',
    mainTitle: 'Localization',
    title: 'Supports Arabic & English',
    subTitle:
        'The app automatically adapts to your preferred language, allowing a seamless experience in both Arabic and English.',
  ),
  OnboardingModel(
    image: 'images/onboarding4.svg',
    mainTitle: 'Ready to Begin?',
    title: 'Start your journey safely with NAGAH',
    subTitle:
        'Know the level of risk on the roads and choose the best route for you easily and in seconds.',
  ),
];
