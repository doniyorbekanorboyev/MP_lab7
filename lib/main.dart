import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

const jsonPlaceholderUrl = 'https://jsonplaceholder.typicode.com/posts';
const postSubmitUrl = 'https://jsonplaceholder.typicode.com/posts';
const cbuBase = 'https://cbu.uz/ru/arkhiv-kursov-valyut/json/';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lecture 7 MP Practice',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _pages = <Widget>[
    PostsPage(),
    NewPostPage(),
    CurrencyPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture 7 — APIs & Networking'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Posts'),
          BottomNavigationBarItem(icon: Icon(Icons.send), label: 'New Post'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Currency'),
        ],
      ),
    );
  }
}

// PART A, B, C: Posts list, loading, error handling, details navigation

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});
  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  List<dynamic>? _posts;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
      _error = null;
      _posts = null;
    });

    try {
      final resp = await http.get(Uri.parse(jsonPlaceholderUrl));
      // Task 2:

      print('Response status: ${resp.statusCode}');
      print(
          'Response body: ${resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length)} ...');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          setState(() => _posts = data);
          if (data.isNotEmpty && data.first is Map) {
            final firstTitle = (data.first as Map)['title'];
            // Task 3
            print('First post title: $firstTitle');
          }
        } else {
          setState(() => _error = 'Unexpected response format.');
        }
      } else {
        setState(
            () => _error = 'Request failed with status: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Task 5:
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      // Task 6:
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchPosts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          ]),
        ),
      );
    }

    if (_posts == null) {
      return Center(
        child: ElevatedButton(
          onPressed: _fetchPosts,
          child: const Text('Load posts'),
        ),
      );
    }

    // Task 4:
    return ListView.separated(
      itemCount: _posts!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final post = _posts![index] as Map<String, dynamic>;
        final title = post['title'] ?? 'No title';
        final subtitle = 'Post #${post['id'] ?? index + 1}';

        return ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Task 7:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailsPage(postMap: post),
              ),
            );
          },
        );
      },
    );
  }
}

class DetailsPage extends StatelessWidget {
  final Map postMap;
  const DetailsPage({super.key, required this.postMap});

  @override
  Widget build(BuildContext context) {
    // Task 8:
    final title = postMap['title'] ?? 'No title';
    final body = postMap['body'] ?? 'No body';

    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ]),
      ),
    );
  }
}

// PART D: POST Request (New Post screen)

class NewPostPage extends StatefulWidget {
  const NewPostPage({super.key});
  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final Map<String, dynamic> payload = {
      'title': _titleCtrl.text.trim(),
      'body': _bodyCtrl.text.trim(),
      'userId': 1
    };

    try {
      final resp = await http.post(
        Uri.parse(postSubmitUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('POST response status: ${resp.statusCode}');
      print('POST response body: ${resp.body}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // Task 10:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post submitted successfully.')),
          );

          _titleCtrl.clear();
          _bodyCtrl.clear();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission failed: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during submission: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Task 9:
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
                labelText: 'Title', border: OutlineInputBorder()),
            textInputAction: TextInputAction.next,
            autofocus: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bodyCtrl,
            decoration: const InputDecoration(
                labelText: 'Body', border: OutlineInputBorder()),
            maxLines: 6,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter the body'
                : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(_submitting ? 'Submitting...' : 'Submit'),
          ),
        ]),
      ),
    );
  }
}

// PART E: Central Bank of Uzbekistan (CBU.uz) Currency API

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});
  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<dynamic>? _results;

  bool _isValidDate(String s) {
    if (s.trim().isEmpty) return false;
    final dt = DateTime.tryParse(s);
    return dt != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s);
  }

  Future<void> _fetchRates() async {
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });

    try {
      final rawDate = _dateCtrl.text.trim();
      final code = _codeCtrl.text.trim().toUpperCase();

      Uri uri;
      if (rawDate.isEmpty) {
        // Endpoint: https://cbu.uz/ru/arkhiv-kursov-valyut/json/
        uri = Uri.parse(cbuBase);
      } else {
        if (!_isValidDate(rawDate)) {
          setState(() {
            _error = 'Date must be in YYYY-MM-DD format.';
            _loading = false;
          });
          return;
        }
        if (code.isEmpty || code.toLowerCase() == 'all') {
          // https://cbu.uz/ru/arkhiv-kursov-valyut/json/all/<date>/
          uri = Uri.parse('${cbuBase}all/$rawDate/');
        } else {
          // https://cbu.uz/ru/arkhiv-kursov-valyut/json/<CODE>/<date>/
          uri = Uri.parse('${cbuBase}$code/$rawDate/');
        }
      }

      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          setState(() => _results = data);
        } else if (data is Map) {
          setState(() => _results = [data]);
        } else {
          setState(() => _error = 'Unexpected response format from CBU.');
        }
      } else {
        setState(() => _error = 'Request failed: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildResultTile(Map m) {
    final code = m['Ccy'] ?? m['Code'] ?? '—';
    final rate = m['Rate'] ?? m['rate'] ?? m['RateValue'] ?? m['Value'] ?? '—';
    final name = m['CcyNm_RU'] ??
        m['CcyNm_UZ'] ??
        m['CcyNm_EN'] ??
        m['CcyNm'] ??
        m['Name'] ??
        '-';

    return ListTile(
      title: Text('$name'),
      subtitle: Text('Code: $code'),
      trailing: Text('$rate UZS'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        TextField(
          controller: _dateCtrl,
          decoration: const InputDecoration(
            labelText: 'Date (YYYY-MM-DD) — leave empty for today',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeCtrl,
          decoration: const InputDecoration(
            labelText: 'Currency code (USD, RUB or all) — leave empty for all',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _fetchRates,
              icon: const Icon(Icons.search),
              label: const Text('Fetch Rates'),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              _dateCtrl.clear();
              _codeCtrl.clear();
              setState(() {
                _results = null;
                _error = null;
              });
            },
            child: const Icon(Icons.clear),
          )
        ]),
        const SizedBox(height: 12),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: _results == null
              ? const Center(
                  child:
                      Text('No data. Enter date/code and press "Fetch Rates".'))
              : _results!.isEmpty
                  ? const Center(child: Text('No results returned.'))
                  : ListView.separated(
                      itemCount: _results!.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _results![index];
                        if (item is Map) {
                          return _buildResultTile(item);
                        } else {
                          return ListTile(title: Text(item.toString()));
                        }
                      },
                    ),
        ),
      ]),
    );
  }
}
