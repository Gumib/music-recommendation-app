import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_recommendation_app/components/random_circles.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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

  // loading state
  bool _isLoading = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a mood and at least one genre"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // prompt text using mood and genres selected
    final promptText = 'I want just a listed music playlist for'
        'Mood: $_selectedMood, Genres: ${_selectedGenres.join(', ')}'
        'in the format artist, title';

    // API call to get playlist recommendations
    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${dotenv.env["token"]},"
      },
      body: jsonEncode(
        {
          "model": "gpt-3.5-turbo-0125",
          "messages": [
            {"role": "system", "content": promptText},
          ],
          "max-tokens": 250,
          "temperature": 0,
          "top_p": 1,
        },
      ),
    );

    // print response in console for debugging
    print(response.body);

    //
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final choices = data["choices"] as List;
      final playlistString =
          choices.isEmpty ? choices[0]["messages"]["contents"] as String : "";

      setState(() {
        // split playlist by newline
        _playlist = playlistString.split("\n").map((song) {
          final parts = song.split(" - ");

          if (parts.length >= 2) {
            return {"artist": parts[0].trim(), "title": parts[1].trim()};
          } else {
            // handle case where song format not expected
            return {"artist": "Unknown Artist", "title": "Unkown Song"};
          }
        }).toList();
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Oops! There seems to be an error. Please try again."),
        ),
      );
    }
  }

  // function to call first screen
  void _showFirstColumn() {
    setState(() {
      _playlist = [];
      _selectedGenres.clear();
    });
  }

  // functions to open spotify and audiomack
  Future<void> _openSpotify() async {
    final playlistQuery = _playlist
        .map((song) => '${song['artist']} - ${song['title']}')
        .join(', ');
    final url = Uri.parse('https://open.spotify.com/search/$playlistQuery');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _openAudiomack() async {
    final playlistQuery = _playlist
        .map((song) => '${song['artist']} - ${song['title']}')
        .join(', ');
    final url = Uri.parse('https://audiomack.com/search/$playlistQuery');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
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
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : _playlist.isEmpty
                  ? Column(
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
                                  padding: EdgeInsets.only(
                                      left: 10, right: 10, top: 5),
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
                                                if (_selectedGenres
                                                    .contains(genre)) {
                                                  _selectedGenres.remove(genre);
                                                } else {
                                                  _selectedGenres.add(genre);
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(3),
                                              margin: EdgeInsets.only(
                                                  right: 4, top: 4),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  width: 0.5,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.blue
                                                      : Colors.white.withValues(
                                                          alpha: 0.8),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),

                                                // text for each genre
                                                child: Text(
                                                  genre,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                  padding: EdgeInsets.only(
                                      top: 60, left: 10, right: 10),
                                  child: GestureDetector(
                                    onTap: _submitSelections,
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 15),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: const Color.fromARGB(
                                            255, 235, 73, 127),
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
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(
                                                "Create Playlist With:",
                                                style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                              content: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // spotify
                                                  GestureDetector(
                                                    onTap: _openSpotify,
                                                    child: Container(
                                                      height: 50,
                                                      width: 50,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: DecorationImage(
                                                            image: AssetImage(
                                                                "assets/images/spotify.png"),
                                                            fit: BoxFit.cover),
                                                      ),
                                                    ),
                                                  ),

                                                  SizedBox(
                                                    width: 8,
                                                  ),

                                                  // audiomack
                                                  GestureDetector(
                                                    onTap: _openAudiomack,
                                                    child: Container(
                                                      height: 50,
                                                      width: 50,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: DecorationImage(
                                                            image: AssetImage(
                                                                "assets/images/audiomack.png"),
                                                            fit: BoxFit.cover),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          });
                                    },
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle),
                                      child: Center(
                                        child: Icon(Icons.playlist_add_rounded),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // image of selected mood
                              Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: _selectedMoodImage != null
                                      ? BoxDecoration(
                                          image: DecorationImage(
                                            image:
                                                AssetImage(_selectedMoodImage!),
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  padding: EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                      width: 0.4,
                                    ),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    // selected mood text
                                    child: Text(
                                      _selectedMood ?? "",
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Container(
                            margin: EdgeInsets.only(top: 20),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top:
                                    BorderSide(width: 0.4, color: Colors.white),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Playlist",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(0),
                            itemCount: _playlist.length,
                            itemBuilder: (BuildContext context, int index) {
                              final song = _playlist[index];

                              return Padding(
                                padding: EdgeInsets.only(
                                    left: 16, right: 16, bottom: 16),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 214, 70, 118)
                                            .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        color: const Color.fromARGB(
                                                255, 214, 70, 118)
                                            .withValues(alpha: 0.3),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Container(
                                          width: 65,
                                          height: 65,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            image: DecorationImage(
                                                image: AssetImage(
                                                    "assets/images/sonnetlogo.png"),
                                                fit: BoxFit.cover),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // artist name
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              child: Text(
                                                song["artist"]!.substring(3),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.white,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),

                                            // title
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              child: Text(
                                                song["title"]!,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ),

      // floating action button
      floatingActionButton: _playlist.isEmpty
          ? Container()
          : Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pink.withValues(alpha: 0.3),
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
                onPressed: _showFirstColumn,
                child: Icon(Icons.add),
              ),
            ),
    );
  }
}
