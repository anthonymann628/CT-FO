import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/app_state.dart';
import '../services/sync_service.dart';
import '../widgets/loading_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load any existing route from local database
    DatabaseService.getStops().then((localStops) {
      if (!mounted) return;
      if (localStops.isNotEmpty) {
        Provider.of<AppState>(context, listen: false).setStops(localStops);
      }
    });
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch route from backend
      List<Stop>? fetchedStops = await SyncService.fetchRoute();
      if (fetchedStops != null && fetchedStops.isNotEmpty) {
        // Update app state and navigate to route details
        Provider.of<AppState>(context, listen: false).setStops(fetchedStops);
        Navigator.of(context).pushNamed('/routeDetails');
      } else {
        setState(() {
          _error = 'No route data available.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load route. Please check your connection.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _syncData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      bool success = await SyncService.syncPendingData();
      if (success) {
        // If route is completed, clear local data for new route
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.stops.isNotEmpty && appState.stops.every((s) => s.delivered)) {
          appState.setStops([]);
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Data synchronized successfully.' : 'Data sync failed.'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Data sync failed.'),
      ));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    Widget content;
    if (_loading) {
      content = const LoadingIndicator();
    } else if (!appState.routeLoaded) {
      // No route loaded yet
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: _loadRoute,
            child: const Text('Download Route'),
          ),
        ],
      );
    } else {
      // Route is loaded
      int totalStops = appState.stops.length;
      int completedStops = appState.stops.where((s) => s.delivered).length;
      content = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Route Loaded: $totalStops stops', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            Text('Completed: $completedStops / $totalStops'),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/routeDetails');
              },
              child: const Text('View Route Details'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: completedStops > 0 ? _syncData : null,
              child: const Text('Sync Data'),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: Center(child: content),
    );
  }
}
