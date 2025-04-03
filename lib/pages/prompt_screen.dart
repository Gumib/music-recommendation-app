import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/random_circles.dart';
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
    "Hip-Hop",
    "R&B",
    "Reggae",
    "Deep House",
    "Gqom",
    "Afrobeat",
    "Blues",
    "Country",
    "Classical",
    "Pop",
    "Punk",
    "Karaoke",
    "Indie",
    "80s",
    "Dance",
    "Hardcore",
    "Alternative",
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
        const SnackBar(
            content: Text("Please select a mood and at least one genre")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final promptText = 'I want just a listed music playlist for '
        'Mood: $_selectedMood, Genres: ${_selectedGenres.join(', ')} '
        'in the format artist, title';

    try {
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${dotenv.env["token"]}",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "user", "content": promptText}
          ],
          "max_tokens": 250,
          "temperature": 0,
          "top_p": 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data["choices"][0]["message"]["content"];

        setState(() {
          _playlist = content.split('\n').map((song) {
            final parts = song.split(" - ");
            return parts.length >= 2
                ? {"artist": parts[0].trim(), "title": parts[1].trim()}
                : {"artist": "Unknown Artist", "title": "Unknown Song"};
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('API request failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Oops! There seems to be an error. Please try again.")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 48, 3, 3), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 50, right: 16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _playlist.isEmpty
                  ? _buildSelectionUI()
                  : _buildPlaylistUI(),
        ),
      ),
      floatingActionButton: _playlist.isEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _showFirstColumn,
              child: const Icon(Icons.refresh, color: Colors.black),
            ),
    );
  }

  Widget _buildSelectionUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood selection with fixed height
                SizedBox(
                  height: constraints.maxHeight * 0.45,
                  child: RandomCircles(
                    onMoodSelected: (mood, image) {
                      setState(() {
                        _selectedMood = mood;
                        _selectedMoodImage = image;
                      });
                    },
                  ),
                ),

                // Genre selection with scrollable content
                SizedBox(
                  height: constraints.maxHeight * 0.55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Genre",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),

                      // Scrollable genre chips
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: genres.map((genre) {
                              final isSelected =
                                  _selectedGenres.contains(genre);
                              return ChoiceChip(
                                label: Text(genre),
                                selected: isSelected,
                                onSelected: (_) => _onGenreSelect(genre),
                                selectedColor:
                                    const Color.fromARGB(255, 235, 73, 127),
                                backgroundColor: Colors.white.withOpacity(0.8),
                                labelStyle: GoogleFonts.inter(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Submit button
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 40),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitSelections,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 235, 73, 127),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              "Submit",
                              style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistUI() {
    return Column(
      children: [
        // Mood display header
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              // Music service options
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.playlist_add, color: Colors.white),
                  onPressed: () => _showMusicServiceDialog(),
                ),
              ),

              // Selected mood image
              if (_selectedMoodImage != null)
                Center(
                  child: Image.asset(
                    _selectedMoodImage!,
                    width: 200,
                    height: 200,
                  ),
                ),

              // Selected mood label
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedMood ?? "",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Playlist title
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Playlist",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),

        // Playlist items
        Expanded(
          flex: 7,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _playlist.length,
            itemBuilder: (context, index) {
              final song = _playlist[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color.fromARGB(255, 214, 70, 118)
                        .withOpacity(0.3),
                    backgroundImage:
                        const AssetImage("assets/images/sonnetlogo.png"),
                  ),
                  title: Text(
                    song['title'] ?? 'Unknown',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    song['artist'] ?? 'Unknown Artist',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMusicServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Create Playlist With:",
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Image.asset("assets/images/spotify.png"),
              iconSize: 50,
              onPressed: () {
                Navigator.pop(context);
                _openSpotify();
              },
            ),
            IconButton(
              icon: Image.asset("assets/images/audiomack.png"),
              iconSize: 50,
              onPressed: () {
                Navigator.pop(context);
                _openAudiomack();
              },
            ),
          ],
        ),
      ),
    );
  }
}
