// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       backgroundColor: Color(0xFFE57373),
//       title: Text("Register Item", style: GoogleFonts.lora()),
//       titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
//       centerTitle: true,
//       automaticallyImplyLeading: false,
//       leading: IconButton(
//         onPressed: () {
//           Navigator.push(context, MaterialPageRoute(builder: (context) => Admin()));
//         },
//         icon: Icon(Icons.arrow_back),
//       ),
//     ),
//     body: SingleChildScrollView(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           SizedBox(height: 10),
//           Stack(
//             children: [
//               CircleAvatar(
//                 radius: 100,
//                 backgroundImage: file != null
//                     ? FileImage(file!)
//                     : pickfile != null
//                     ? NetworkImage(pickfile!.path) as ImageProvider
//                     : null, // This will display nothing if no image is selected
//                 backgroundColor: Colors.grey[200],
//                 child: file == null && pickfile == null
//                     ? Icon(Icons.image, size: 100, color: Colors.grey) // Default icon when no image is selected
//                     : null,
//               ),
//               Positioned(
//                 bottom: 0,
//                 right: 0,
//                 child: IconButton(
//                   icon: Icon(Icons.camera_alt, color: Colors.blue, size: 30),
//                   onPressed: getImage, // Function to pick image
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 10),
//           // Rest of your UI elements (TextFields, DropdownButton, etc.)
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: nc,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
//                 filled: true,
//                 labelText: "Name",
//                 labelStyle: TextStyle(fontSize: 15),
//                 hintText: "Enter your Name",
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: dc,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
//                 filled: true,
//                 labelText: "Description",
//                 labelStyle: TextStyle(fontSize: 15),
//                 hintText: "Enter your Description",
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: rc,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
//                 filled: true,
//                 labelText: "Rate",
//                 labelStyle: TextStyle(fontSize: 15),
//                 hintText: "Enter your Rate",
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: categories.isNotEmpty
//                       ? DropdownButtonFormField<String>(
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
//                       filled: true,
//                       labelText: "Category",
//                       labelStyle: TextStyle(fontSize: 15),
//                     ),
//                     value: category.isEmpty ? null : category,
//                     items: categories.map((String value) {
//                       return DropdownMenuItem<String>(
//                         value: value,
//                         child: Text(value),
//                       );
//                     }).toList(),
//                     onChanged: (newValue) {
//                       setState(() {
//                         category = newValue!;
//                       });
//                     },
//                   )
//                       : CircularProgressIndicator(),
//                 ),
//                 IconButton(
//                   onPressed: () {
//                     Navigator.push(context, MaterialPageRoute(builder: (context) => AddCategory()));
//                   },
//                   icon: Icon(Icons.add, size: 40),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 20),
//           Card(
//             color: Colors.black,
//             child: InkWell(
//               onTap: getImage,
//               child: Container(
//                 width: 200.0,
//                 height: 50.0,
//                 decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(20))),
//                 child: Center(
//                   child: Text(
//                     "Pick Image",
//                     style: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Card(
//             color: Colors.black,
//             child: InkWell(
//               onTap: isSaving
//                   ? null
//                   : () async {
//                 setState(() {
//                   isSaving = true;
//                 });
//                 item_name = nc.text.toString();
//                 description = dc.text.toString();
//                 rate = rc.text.toString();
//                 if (item_name.isEmpty || description.isEmpty || rate.isEmpty || category.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please Enter The Fields")));
//                   setState(() {
//                     isSaving = false;
//                   });
//                 } else {
//                   await upload_Image();
//                   save();
//                 }
//               },
//               child: Container(
//                 width: 200.0,
//                 height: 50.0,
//                 decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.all(Radius.circular(20))),
//                 child: Center(
//                   child: Text(
//                     isSaving ? "Saving..." : "Save Data",
//                     style: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
