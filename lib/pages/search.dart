
import 'dart:io';

import 'package:file_manager_app/pages/Home_screen.dart';
import 'package:flutter/material.dart';

class FileSearchDelegate extends SearchDelegate {
  final List<FileSystemEntity> filesAndFolders;

  FileSearchDelegate(this.filesAndFolders);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = filesAndFolders.where((entity) {
      return entity.path.split('/').last.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entity = results[index];
        final isDirectory = entity is Directory;
        return ListTile(
          title: Text(entity.path.split('/').last),
          leading: Icon(isDirectory ? Icons.folder : Icons.insert_drive_file),
          onTap: () {
            if (isDirectory) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(directory: entity),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = filesAndFolders.where((entity) {
      return entity.path.split('/').last.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final entity = suggestions[index];
        return ListTile(
          title: Text(entity.path.split('/').last),
          onTap: () {
            query = entity.path.split('/').last;
            showResults(context);
          },
        );
      },
    );
  }
}
