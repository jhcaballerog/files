// Importación de paquetes necesarios
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
// Punto de entrada de la aplicación
void main() {
  runApp(UnfvApp());
}

// Widget principal de la aplicación
class UnfvApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNFV App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Roboto',
      ),
      home: LoginPage(), // Página de inicio de sesión como pantalla de inicio
    );
  }
}

//* Página de inicio de sesión
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores para los campos de entrada de usuario y contraseña
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Función para manejar el inicio de sesión
  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    // Hacer una solicitud HTTP para autenticar al usuario
    final response = await http.get(
      Uri.parse('https://pidm-be.onrender.com/auth/login/$username/$password'),
    );

    // Verificar la respuesta de la solicitud HTTP
    if (response.statusCode == 200) {
      final responseData = response.body;

      // Decodificar la respuesta JSON
      final List<dynamic> data = json.decode(responseData);
      if (data.isNotEmpty) {
        final userData = data[0];
        final codigoInstitucional = userData['codigo_institucional'];
        final nivelAcceso = userData['id_nivel_acceso'];

        // Si el nivel de acceso es 1 (estudiante), navegar a la página de datos del estudiante
        if (nivelAcceso == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDataPage(codigoInstitucional),
            ),
          );
            } else if (nivelAcceso == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDataPage(codigoInstitucional), // Reemplaza "TeacherDataPage" con el nombre de tu página de datos de profesor
            ),
          );
        } else {
          // Mostrar un mensaje si las credenciales no son válidas
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuario y/o contraseña incorrecto')),
          );
        }
      }
    } else {
      // Mostrar un mensaje si hay un error en la solicitud HTTP
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en la solicitud')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Interfaz de usuario para la página de inicio de sesión
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Campo de entrada de usuario
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Usuario'),
              ),
              SizedBox(height: 10),
              // Campo de entrada de contraseña
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              // Botón para iniciar sesión
              ElevatedButton(
                onPressed: _login,
                child: Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//* Página que muestra los datos del estudiante y sus cursos
class StudentDataPage extends StatefulWidget {
  final String codigoInstitucional;

  StudentDataPage(this.codigoInstitucional);

  @override
  _StudentDataPageState createState() => _StudentDataPageState();
}

// Estado de la página de datos del estudiante
class _StudentDataPageState extends State<StudentDataPage> {
  Map<String, dynamic> studentInfo = {}; // Almacenar la información del estudiante
  List<Map<String, dynamic>> coursesData = []; // Almacenar la información de los cursos
  String selectedPeriod = 'Todos'; // Período seleccionado para filtrar cursos

  @override
  void initState() {
    super.initState();
    _fetchStudentInfo(); // Obtener información del estudiante
    _fetchCoursesData(); // Obtener información de los cursos
  }

  // Función para obtener información del estudiante
  Future<void> _fetchStudentInfo() async {
    final response = await http.get(
      Uri.parse('https://pidm-be.onrender.com/api/student/${widget.codigoInstitucional}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        setState(() {
          studentInfo = data[0];
        });
      }
    }
  }

  // Función para obtener información de los cursos
  Future<void> _fetchCoursesData() async {
    final response = await http.get(
      Uri.parse('https://pidm-be.onrender.com/api/studentSection/${widget.codigoInstitucional}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        coursesData = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  // Obtener una lista de períodos únicos para filtrar
  List<String> getUniquePeriods() {
    List<String> uniquePeriods = [];
    for (var course in coursesData) {
      if (!uniquePeriods.contains(course['periodo_academico'])) {
        uniquePeriods.add(course['periodo_academico']);
      }
    }
    return uniquePeriods;
  }

  @override
  Widget build(BuildContext context) {
    final uniquePeriods = getUniquePeriods(); // Obtener los períodos únicos de los cursos

    return Scaffold(
      appBar: AppBar(
        title: Text('Datos del Estudiante'),
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mostrar información del estudiante en una tarjeta
            SizedBox(height: 20),
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código Institucional: ${widget.codigoInstitucional}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (studentInfo.isNotEmpty) ...[
                      SizedBox(height: 10),
                      Text(
                        'Nombre: ${studentInfo['nombre_completo']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Escuela: ${studentInfo['escuela']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Año de Malla: ${studentInfo['ano_malla']}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Mostrar la selección de período y la lista de cursos
            SizedBox(height: 20),
            Text(
              'Cursos y Notas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedPeriod,
              onChanged: (String? newValue) {
                setState(() {
                  selectedPeriod = newValue!;
                });
              },
              items: ['Todos', ...uniquePeriods].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: 16)),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Mostrar los elementos de los cursos si corresponden al período seleccionado
            for (var course in coursesData)
              if (selectedPeriod == 'Todos' || course['periodo_academico'] == selectedPeriod)
                CourseItem(course: course),
          ],
        ),
      ),
    );
  }
}

// Widget para mostrar la información de un curso
class CourseItem extends StatefulWidget {
  final Map<String, dynamic> course;

  CourseItem({required this.course});

  @override
  _CourseItemState createState() => _CourseItemState();
}

// Estado del elemento del curso
class _CourseItemState extends State<CourseItem> {
  bool _expanded = false; // Para controlar si se muestra la información detallada del curso

  // Función para formatear un valor nulo
  String? formatNullableValue(dynamic value) {
    return value != null ? value.toString() : '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        child: Column(
          children: [
            // Mostrar información resumida del curso
            ListTile(
              title: Text('${widget.course['nombre_curso']}'),
              subtitle: Text('Nota Final: ${formatNullableValue(widget.course['nota_final'])}'),
              trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            ),
            // Mostrar información detallada del curso si está expandido
            if (_expanded)
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Periodo Académico: ${widget.course['periodo_academico']}'),
                    Text('Examen Parcial: ${formatNullableValue(widget.course['examen_parcial'])}'),
                    Text('Examen Final: ${formatNullableValue(widget.course['examen_final'])}'),
                    Text('Promedio de Prácticas: ${formatNullableValue(widget.course['promedio_practicas'])}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}


//* PAGINA DE DATOS DEL PROFESOR

class TeacherDataPage extends StatefulWidget {
  final String codigoInstitucional;

  TeacherDataPage(this.codigoInstitucional);

  @override
  _TeacherDataPageState createState() => _TeacherDataPageState();
}

class _TeacherDataPageState extends State<TeacherDataPage> {
  String teacherName = "";
  String teacherFaculty = "";
  List<Map<String, dynamic>> courses = [];

  @override
  void initState() {
    super.initState();
    fetchTeacherInfo();
    fetchTeacherCourses();
  }

  Future<void> fetchTeacherInfo() async {
    final response = await http.get(
      Uri.parse('https://pidm-be.onrender.com/api/teacher/${widget.codigoInstitucional}'),
    );

    if (response.statusCode == 200) {
      final responseData = response.body;
      final List<dynamic> data = json.decode(responseData);
      if (data.isNotEmpty) {
        final info = data[0]['obtener_info_profesor'];
        final infoList = info.substring(1, info.length - 1).split('","');
        setState(() {
          teacherName = infoList[0];
          teacherFaculty = infoList[1];
        });
      }
    }
  }

Future<void> fetchTeacherCourses() async {
  final response = await http.get(
    Uri.parse('https://pidm-be.onrender.com/api/teacherlist/${widget.codigoInstitucional}'),
  );

  if (response.statusCode == 200) {
    final responseData = response.body;
    final List<dynamic> data = json.decode(responseData);
    setState(() {
      courses = List<Map<String, dynamic>>.from(data);
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Datos del Profesor'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre: $teacherName',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Facultad: $teacherFaculty',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Cursos a Cargo:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return ListTile(
                  title: Text(course['nombre_curso']),
                          subtitle: Text(
                      '${course['nombre_escuela']} - ${course['nombre_malla_curricular'].split("_")[1]} - Sección: ${course['secc_curso']}',
                    ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDataPage(course['id_curso_asignado']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//* INICIO DE INTERFAZ DETALLES DE CURSO



class CourseDataPage extends StatefulWidget {
  final int courseId;

  CourseDataPage(this.courseId);

  @override
  _CourseDataPageState createState() => _CourseDataPageState();
}

class _CourseDataPageState extends State<CourseDataPage> {
  Map<String, dynamic> courseData = {};
  List<Map<String, dynamic>> studentData = [];

  @override
  void initState() {
    super.initState();
    fetchCourseData();
    fetchStudentData();
  }

  Future<void> fetchCourseData() async {
    final response = await http.get(
      Uri.parse('https://pidm-be.onrender.com/api/teacherSingleSubj/${widget.courseId}'),
    );

    if (response.statusCode == 200) {
      final responseData = response.body;
      final List<dynamic> data = json.decode(responseData);
      if (data.isNotEmpty) {
        setState(() {
          courseData = data[0];
        });
      }
    }
  }

  Future<void> fetchStudentData() async {
    final response = await http.get(
      Uri.parse('https://pidm-be.onrender.com/api/teacherStudents/${widget.courseId}'),
    );

    if (response.statusCode == 200) {
      final responseData = response.body;
      final List<dynamic> data = json.decode(responseData);
      setState(() {
        studentData = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> updateStudentNotes(int courseId, int studentId, Map<String, dynamic> updatedNotes) async {
    final response = await http.put(
      Uri.parse('https://pidm-be.onrender.com/api/updateStudentNotes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id_curso_matriculado': courseId,
        'id_alumno': studentId,
        ...updatedNotes,
      }),
    );

    if (response.statusCode == 200) {
      // Successfully updated, you can handle the response accordingly
    } else {
      // Handle error here
    }
  }

  Widget buildEditableField(Map<String, dynamic> student, String field) {
    return Expanded(
      child: TextFormField(
        initialValue: student[field]?.toString() ?? '',
        keyboardType: TextInputType.number,
        onChanged: (value) {
          setState(() {
            student[field] = value;
          });
        },
        onFieldSubmitted: (value) {
          updateStudentNotes(widget.courseId, student['id_alumno'], {field: value});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Curso'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre del Curso: ${courseData['nombre_curso']}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Escuela: ${courseData['nombre_escuela']}'),
                    Text('Año: ${courseData['nombre_malla_curricular'] ?? ''}'),
                    Text('Sección: ${courseData['secc_curso']}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Alumnos y Notas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: studentData.length,
                itemBuilder: (context, index) {
                  final student = studentData[index];
                  return Column(
                    children: [
                      ExpansionTile(
                        title: Text('${student['id_alumno']}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: [
                                if (student['nombre_completo'] != null)
                                  ListTile(
                                    title: Text('Nombre Completo'),
                                    subtitle: Text(student['nombre_completo']),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildEditableField(student, 'examen_parcial'),
                          buildEditableField(student, 'promedio_practicas'),
                          buildEditableField(student, 'examen_final'),
                          buildEditableField(student, 'nota_final'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

