import 'package:file_manager_app/pages/search.dart';
import 'package:file_manager_app/pages/video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  final Directory? directory;

  HomeScreen({this.directory});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Directory? currentDir;
  String? _selectedSortOption = 'Name';
  String? _selectedFilterOption = 'All';
   Set<FileSystemEntity> _selectedFiles = {}; 
  bool _isSelectionMode = false; 

  @override
  void initState() {
    super.initState();
    _getRootDir();
    _requestPermissions();
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('New Folder'),
              onTap: () {
                Navigator.pop(context);
                _showCreateDialog(isFile: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('New File'),
              onTap: () {
                Navigator.pop(context);
                _showCreateDialog(isFile: true);
              },
            ),
          ],
        );
      },
    );
  }
    void _editTextFile(File file) async {
    String content = await file.readAsString();
    TextEditingController controller = TextEditingController(text: content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit File'),
          content: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Edit the content here',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await file.writeAsString(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File saved successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showFileDetails(FileSystemEntity entity) async {
 
  FileStat stat = await entity.stat();
  String type = entity is Directory ? 'Folder' : 'File';
  String size = entity is File ? '${stat.size} bytes' : 'N/A';
  String modified = stat.modified.toString();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('File Details: ${entity.path.split('/').last}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Type: $type'),
            Text('Size: $size'),
            Text('Last Modified: $modified'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}


  void _deleteSelectedItems() {
    for (var entity in _selectedFiles) {
      _confirmDelete(entity);
    }
    setState(() {
      _selectedFiles.clear();
      _isSelectionMode = false; 
    });
  }

 void _toggleSelection(FileSystemEntity entity) {
  setState(() {
    if (_selectedFiles.contains(entity)) {
      _selectedFiles.remove(entity); 
    } else {
      _selectedFiles.add(entity);  
    }

    
    _isSelectionMode = _selectedFiles.isNotEmpty;
  });
}


  void _openFile(File file) async {
    final status = await Permission.storage.status;
    if (status.isGranted) {
      String content = await file.readAsString();
      print(content);
    } else {
      _requestPermissions();
    }
  }


  Future<void> _requestPermissions() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      print('Storage permission granted');
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied.')),
      );
    }
  }

  void _getRootDir() async {
    if (widget.directory != null) {
      setState(() {
        currentDir = widget.directory!;
      });
    } else {
      if (Platform.isAndroid || Platform.isIOS) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          setState(() {
            currentDir = directory;
          });
          final files = await directory.list().toList();
          files.forEach((file) {
            print(file.path);
          });
        } else {
          print("Unable to get external storage directory.");
        }
      } else {
        print("This platform is not supported for file access.");
      }
    }
  }

  void _viewImage(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('View Image')),
          body: Center(child: Image.file(imageFile)),
        ),
      ),
    );
  }

  void _viewPdf(File pdfFile) {
  print('Opening PDF file at: ${pdfFile.path}');
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('View PDF')),
        body: PDFView(
          filePath: pdfFile.path,
          onViewCreated: (PDFViewController pdfViewController) {
            pdfViewController.setPage(0); 
          },
          onPageError: (page, error) {
            print('Error loading page $page: $error');
          },
          onError: (error) {
            print('Error loading PDF: $error');
          },
        ),
      ),
    ),
  );
}

  void _playVideo(File videoFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerWidget(videoFile: videoFile),
      ),
    );
  }

  void _showCreateDialog({required bool isFile}) {
    String entityName = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isFile ? 'Create New File' : 'Create New Folder'),
          content: TextField(
            decoration: InputDecoration(
                hintText: isFile ? 'Enter file name' : 'Enter folder name'),
            onChanged: (value) {
              entityName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (entityName.isNotEmpty && _isValidName(entityName)) {
                  if (isFile) {
                    _createFile(entityName);
                  } else {
                    _createFolder(entityName);
                  }
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid name. Please try again.')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _createFile(String fileName) async {
    final newFile = File('${currentDir!.path}/$fileName.txt');
    if (!await newFile.exists()) {
      await newFile.writeAsString('This is a new file.');
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File already exists.')),
      );
    }
  }

  void _createFolder(String folderName) async {
    final newFolder = Directory('${currentDir!.path}/$folderName');
    if (!await newFolder.exists()) {
      await newFolder.create();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder already exists.')),
      );
    }
  }

  bool _isValidName(String name) {
    final invalidCharacters = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
    return !invalidCharacters.hasMatch(name) && name.isNotEmpty;
  }

  void _deleteFile(FileSystemEntity entity) async {
    if (entity is File) {
      await entity.delete();
    } else if (entity is Directory) {
      await entity.delete(recursive: true);
    }
    setState(() {});
  }

  void _sortFiles(List<FileSystemEntity> filesAndFolders) {
    switch (_selectedSortOption) {
      case 'Name':
        filesAndFolders.sort(
            (a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));
        break;
      case 'Size':
        filesAndFolders.sort((a, b) {
          if (a is File && b is File) {
            return a.lengthSync().compareTo(b.lengthSync());
          }
          return 0;
        });
        break;
      case 'Date Modified':
        filesAndFolders.sort(
            (a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        break;
    }
  }

  void _confirmDelete(FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteFile(entity);
                setState(() {
                  _selectedFiles.remove(entity);
                  if (_selectedFiles.isEmpty) {
                    _isSelectionMode = false; 
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _editFileOrFolder(FileSystemEntity entity) async {
    String oldName = entity.path.split('/').last;
    String newName = oldName;

    TextEditingController controller = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new name'),
            onChanged: (value) {
              newName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (newName.isNotEmpty && _isValidName(newName)) {
                  String newPath = entity.parent.path + '/' + newName;
                  try {
                    if (entity is File) {
                      await entity.rename(newPath);
                    } else if (entity is Directory) {
                      await (entity as Directory).rename(newPath);
                    }
                    setState(() {});
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Failed to rename. Operation not permitted.')),
                    );
                    print('Error renaming file or folder: $e');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid name. Please try again.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  List<FileSystemEntity> _filterFiles(List<FileSystemEntity> filesAndFolders) {
    switch (_selectedFilterOption) {
      case 'Text Files':
        return filesAndFolders
            .where((entity) => entity.path.endsWith('.txt'))
            .toList();
      case 'Images':
        return filesAndFolders
            .where((entity) =>
                entity.path.endsWith('.jpg') || entity.path.endsWith('.png'))
            .toList();
      default:
        return filesAndFolders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentDir?.path.split('/').last ?? "File Manager"),
        leading: currentDir?.parent != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    currentDir = currentDir!.parent;
                    _selectedFiles.clear(); 
                    _isSelectionMode = false;
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete,color: Colors.red),
              onPressed: () {
                _deleteSelectedItems();
              },
            ),
          DropdownButton<String>(
            value: _selectedSortOption,
            items: [
              'Name',
              'Size',
              'Date Modified',
              'All',
              'Text Files',
              'Images'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSortOption = newValue;
                _selectedFilterOption = newValue;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (currentDir != null) {
                showSearch(
                  context: context,
                  delegate: FileSearchDelegate(
                    currentDir!.listSync(),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddOptions();
            },
          ),
        ],
      ),
      body: currentDir == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<FileSystemEntity>>(
              future: currentDir!.list().toList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                List<FileSystemEntity> filesAndFolders = snapshot.data ?? [];
                

                _sortFiles(filesAndFolders);

                filesAndFolders = _filterFiles(filesAndFolders);
                for (var entity in filesAndFolders) {
          print('File path: ${entity.path}');
          print('File extension: ${entity.path.split('.').last.toLowerCase()}');
        }
          
        
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: filesAndFolders.length,    
                  itemBuilder: (context, index) {
                    final entity = filesAndFolders[index];
                    final isDirectory = entity is Directory;
                    final fileName = entity.path.split('/').last;

                    return GestureDetector(
                      onLongPress: () {
                
                        _toggleSelection(entity);
                      },
                      onTap: () {
                        
                        if (_selectedFiles.contains(entity)) {
                          return;
                        }

                        if (isDirectory) {
                          setState(() {
                            currentDir = entity;
                            _selectedFiles.clear(); 
                            _isSelectionMode = false;
                          });
                        } else {
      
                          final fileExtension =
                              fileName.split('.').last.toLowerCase();
                              if (fileExtension == 'txt') {
                            _editTextFile(File(entity.path));
                          } 
                          if (fileExtension == 'jpg' ||
                              fileExtension == 'png') {
                            _viewImage(File(entity.path));
                          } else if (fileExtension == 'mp4' ||
                              fileExtension == 'avi') {
                            _playVideo(File(entity.path));
                          } else if (fileExtension == 'pdf') {
                            _viewPdf(File(entity.path));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Unsupported file type.')),
                            );
                          }
                        }
                      },
                      child: GridTile(
                        footer: Container(
                          
                          color: _selectedFiles.contains(entity)
                              ? Colors.blue.withOpacity(0.5)
                              : Colors.transparent,
                          child: Column(
                            children: [
                              Text(fileName,),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      _editFileOrFolder(entity);
                                    },
                                  ),
                                 IconButton(
                                    icon: const Icon(Icons.info,
                                        color: Colors.blue),
                                    onPressed: () {
                                      _showFileDetails(entity);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        child: Icon(
                          isDirectory ? Icons.folder : Icons.insert_drive_file,
                          size: 50.0,
                          color: isDirectory ? Colors.blue : Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
