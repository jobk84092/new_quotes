import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:introduction_screen/introduction_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_quotes/homepage.dart';
import 'package:new_quotes/onboarding_gate.dart';

/// Onboarding screens - no network/data loading. Completes immediately.
/// HomePage (with data) loads only when user taps Done/Skip.
class IntroductionScreens extends StatelessWidget {
  const IntroductionScreens({super.key});

  Future<void> _redirectToHomePage(BuildContext context) async {
    await markOnboardingComplete();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }
  @override
  Widget build(BuildContext context) {
    final quicksandFontFamily = GoogleFonts.quicksand().fontFamily;
    return Scaffold(
      // appBar: AppBar(),
      body: IntroductionScreen(
          pages: [
            PageViewModel(
              title: 'Inspirational & Motivational Quotes',
              body: 'Elevate your day: 120K+ Quotes to Spark Your Mood.',
              image: buildImage("assets/logo/playstore.png"),
              decoration: getPageDecoration(),
            ),
            PageViewModel(
              title: 'Tailored Daily Notifications',
              body: 'Customize your inspiration: Personalized quotes and notifications just for you!',
              image: buildImage("assets/images/quotes_2.png"),
              decoration: getPageDecoration(),
            ),
            PageViewModel(
              title: 'Limitless Categories',
              body: 'Navigate 700+ realms of inspiration: Discover your ideal quote in every facet of motivation!"',
              image: buildImage("assets/images/bg2.jpg"),
              decoration: getPageDecoration(),
            ),
            PageViewModel(
              title: 'Empower, Share, Collect',
              body: 'Bookmark, download, share: Elevate your journey with the power of customization!',
              image: buildImage("assets/images/bg2.jpg"),
              decoration: getPageDecoration(),
            ),


          ],
          onDone: () {
            if (kDebugMode) {
              print("Done clicked");
            }
            _redirectToHomePage(context);
          },
          onSkip: () {
            // On Skip button pressed
            _redirectToHomePage(context);
          },
          //ClampingScrollPhysics prevent the scroll offset from exceeding the bounds of the content.
          scrollPhysics: const ClampingScrollPhysics(),
          showDoneButton: true,
          showNextButton: true,
          showSkipButton: true,
          next: Text(
            "Next",
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          done: Text(
            "Done",
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          skip: Text(
            "Skip",
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          dotsDecorator: getDotsDecorator()),

    );
  }

  //widget to add the image on screen
  Widget buildImage(String imagePath) {
    return Center(
        child: Image.asset(
          imagePath,
          width: 450,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ));
  }

  //method to customise the page style
  PageDecoration getPageDecoration() {
    final quicksandFontFamily = GoogleFonts.quicksand().fontFamily;

    return PageDecoration(
      imagePadding: const EdgeInsets.only(top: 120),
      bodyPadding: const EdgeInsets.only(top: 8, left: 20, right: 20),
      titlePadding: const EdgeInsets.only(top: 50),
      bodyTextStyle: GoogleFonts.quicksand(
        color: Colors.white,
        fontSize: 20,
      ),
      titleTextStyle: GoogleFonts.ebGaramond(
        fontSize: 40,
      ),
      // Set gradient background
      boxDecoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF536FFE), Color(0xFFFC66C5)],
        ),
      ),
    );
  }


  //method to customize the dots style
  DotsDecorator getDotsDecorator() {
    return const DotsDecorator(
      spacing: EdgeInsets.symmetric(horizontal: 2),
      activeColor: Color(0xFFFC66C5), // Use a single color for active dots
      color: Color(0xFF536FFE), // Use a single color for inactive dots
      activeSize: Size(10, 10), // Adjust the active dot size
      size: Size(8, 8), // Adjust the inactive dot size
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(25.0)),
      ),
    );
  }
}
