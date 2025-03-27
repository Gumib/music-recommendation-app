import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_recommendation_app/components/random_circles.dart';

class PromptScreen extends StatefulWidget {
  final VoidCallback showHomeScreen;
  const PromptScreen({super.key, required this.showHomeScreen});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  // genre list variables
  List<String> genres = [
    "Jazz",
    "Rock",
    "AmaPiano",
    "Gospel",
    "Hip-Hip",
    "R&B",
    "Raggae",
    "Deep House",
    "Gqom",
    "Afrobeat",
    "Blues",
    "Country",
    "Classical",
    "Pop",
    "Punk"
  ];

  // selected genres list
  final Set<String> _selectedGenres = {};

  // selected mood and selected mood image
  String? _selectedMood;
  String? _selectedMoodImage;

  // playlist generator
  List<Map<String, String>> _playlist = [];

  // function for selected genres
  void _onGenreSelect(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  // function to submit mood and genres to make playlist
  Future<void> _submitSelections() async {
    if (_selectedMood == null || _selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please select a mood and at least one genre")));
      return;
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    // SCAFFOLD
    return Scaffold(
      // BODY
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 48, 3, 3), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            // background image
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 16, top: 50, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // expanded for the moods
              Expanded(child: RandomCircles(
                onMoodSelected: (mood, image) {
                  _selectedMood = mood;
                  _selectedMoodImage = image;
                },
              )),

              // expanded for the genre selection and submit button
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // genre texts
                      Text(
                        "Genre",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),

                      // various genres
                      Padding(
                        padding: EdgeInsets.only(left: 10, right: 10, top: 5),
                        child: StatefulBuilder(
                          builder: (BuildContext context, setState) {
                            return Wrap(
                              children: genres.map((genre) {
                                final isSelected =
                                    _selectedGenres.contains(genre);

                                // container for each genre
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_selectedGenres.contains(genre)) {
                                        _selectedGenres.remove(genre);
                                      } else {
                                        _selectedGenres.add(genre);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(3),
                                    margin: EdgeInsets.only(right: 4, top: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        width: 0.5,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.white
                                                .withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(20),
                                      ),

                                      // text for each genre
                                      child: Text(
                                        genre,
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),

                      // button
                      Padding(
                        padding: EdgeInsets.only(top: 60, left: 10, right: 10),
                        child: GestureDetector(
                          onTap: _submitSelections,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color.fromARGB(255, 235, 73, 127),
                            ),
                            child: Center(
                              child: Text(
                                "Submit",
                                style: GoogleFonts.inter(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
