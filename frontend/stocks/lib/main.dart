import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter_tagging_plus/flutter_tagging_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black, 
          ),
          bodyLarge: TextStyle(fontSize: 20, color: Colors.grey[700]),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          filled: true,
          fillColor: Colors.grey[200],
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blue[400],
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Prediction {
  final int index;
  final double value;

  Prediction(this.index, this.value);
}

class _MyHomePageState extends State<MyHomePage> {
  String tickersymbol = '';

  List<dynamic> predictions = [];

  // Define _predictions variable outside the constructor
  List<charts.Series<Prediction, int>> _predictions = [];

  List<charts.Series<Prediction, int>> _createLineSeries(
      List<Prediction> data) {
    return [
      charts.Series<Prediction, int>(
        id: 'Predictions',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (Prediction prediction, _) => prediction.index,
        measureFn: (Prediction prediction, _) => prediction.value,
        data: data,
      ),
    ];
  }

  bool _isLoading = false;

  Future<void> fetchPredictions(tickersymbol) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await http.post(Uri.parse('http://192.168.1.12:5000/predict'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, String>{
                'ticker_symbol': tickersymbol,
              }));

      if (response.statusCode == 200) {
        setState(() {
          Map<String, dynamic> data = json.decode(response.body);
          predictions = data['prediction'];
          // Update _predictions with processed data
          _predictions = _createLineSeries(predictions
              .map((p) => Prediction(predictions.indexOf(p), p[0]))
              .toList());
        });
      } else {
        throw Exception('Failed to fetch stocks data.');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load predictions: $e'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  // Replace with your actual list of ticker symbols or logic to fetch them
  final List<String> tickerSymbols = [
    "AAPL",
    "ADANIPOWER",
    "HDFCBANK",
    "HDFCLIFE",
    "INFY",
    "ITC",
    "KOTAKBANK",
    "MSFT",
    "RS",
    "SBIN",
    "SPOT",
    "TATASTEEL",
    "TSLA"
  ];

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Price Predictions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TypeAheadFormField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _controller,
                decoration: InputDecoration(
                  prefixIcon:
                      Icon(Icons.business_center, color: Colors.grey[600]),
                  hintText: 'Enter Stocks Name',
                ),
                onChanged: (value) => tickersymbol = value,
              ),
              suggestionsCallback: (pattern) async {
                return tickerSymbols
                    .where((symbol) => symbol.startsWith(pattern))
                    .toList();
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                tickersymbol = suggestion;
                _controller.text = suggestion;
              },
              noItemsFoundBuilder: (context) =>
                  const Text('No Suggestions Found'),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[300]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: ElevatedButton(
                onPressed: () => fetchPredictions(tickersymbol),
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.all(16)),
                  backgroundColor:
                      MaterialStateProperty.all(Colors.transparent),
                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  )),
                ),
                child: const Text('Fetch Predictions',
                    style: TextStyle(
                      fontSize: 20,
                    )),
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator()) // Display loading circle while loading
                : Container(
                    height: 300,
                    child: predictions.isNotEmpty
                        ? charts.LineChart(
                            _predictions, // Pass the generated _predictions data series
                            animate: true,
                            domainAxis: charts.NumericAxisSpec(
                              tickFormatterSpec:
                                  charts.BasicNumericTickFormatterSpec(
                                (value) =>
                                    '${value?.toStringAsFixed(0)}', // Format axis labels
                              ),
                              renderSpec: charts.SmallTickRendererSpec( // Custom renderer
                                labelStyle: charts.TextStyleSpec(
                                  fontSize: 18, // size in Pts.
                                  color: charts.MaterialPalette.blue.shadeDefault, // color of labels
                                ),
                                lineStyle: const charts.LineStyleSpec(
                                  color: charts.MaterialPalette.black, // color of axis line
                                ),
                              ),

                            ),
                            primaryMeasureAxis:const charts.NumericAxisSpec(
                              renderSpec: charts.GridlineRendererSpec(labelStyle: charts.TextStyleSpec(
                                  fontSize: 0, // Set to 0 to hide labels
                                color: charts.MaterialPalette.transparent, // Set color to transparent to hide labels
                              ),
                              lineStyle: charts.LineStyleSpec(
                                thickness: 1, // Set thickness of the line
                                // Set color of the line
                              ),
                              ),
                              
                              
                            ),
                          )
                        : Container(), // Empty container if no predictions yet
                  ),
          ],
        )),
      ),
    );
  }
}
