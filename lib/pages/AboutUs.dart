import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  Widget buildTeamMember(IconData icon, String name, String role) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: const Color.fromARGB(255, 129, 97, 75),
          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 100, // Fixed width for name container
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 12, // Reduced font size
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 129, 97, 75),
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Allow up to 2 lines
            overflow: TextOverflow.ellipsis, // Add ... if text is too long
          ),
        ),
        Text(
          role,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.brown,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white, // Changed to white for better contrast
            ),
            SizedBox(width: 8),
            Text(
              'About Us',
              style: TextStyle(
                color: Colors.white, // Changed to white for better contrast
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 129, 97, 75), // Changed to match monitor color
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white, // Changed to white for better contrast
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.home,
              color: Colors.white, // Changed to white for better contrast
            ),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 223, 197, 151).withOpacity(0.9),
              const Color(0xFFFFF8E1),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            
            const SizedBox(height: 36),
            
           
            const Text(
              'Our Team',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 129, 97, 75),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: buildTeamMember(
                    Icons.person, 
                    'Canindo, Achellis Michael M.', 
                    'LEADER'
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    buildTeamMember(Icons.person, 'Bamba, Michael Angelo L.', 'Member'),
                    buildTeamMember(Icons.person, 'Dalanon, Mariel R.', 'Member'),
                    buildTeamMember(Icons.person, 'Maghanoy, Ceejay P.', 'Member'),
                    buildTeamMember(Icons.person, 'Mandap, Wetherel R.', 'Member'),
                    buildTeamMember(Icons.person, 'Pedernal, John Lester P.', 'Member'),
                    buildTeamMember(Icons.person, 'Peteros, Jemie Rose L.', 'Member'),
                    buildTeamMember(Icons.person, 'Rances Joseph lance', 'Member'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 36),
            
            // Mission and Vision in one box
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Mission Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 129, 97, 75).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.flag,
                            color: Color.fromARGB(255, 129, 97, 75),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Our Mission',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 129, 97, 75),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'To provide quality gas services and ensure safety for every home and business.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.brown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    color: Color.fromARGB(255, 223, 197, 151),
                    thickness: 1,
                  ),

                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 129, 97, 75).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.visibility,
                            color: Color.fromARGB(255, 129, 97, 75),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Our Vision',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 129, 97, 75),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'To be the leading provider of safe and reliable gas solutions in the region.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.brown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: const Column(
                children: [
                  Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 129, 97, 75),
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.email, color: Color.fromARGB(255, 129, 97, 75)),
                    title: Text('Email'),
                    subtitle: Text('mandapwetherel@gmail.com'),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone, color: Color.fromARGB(255, 129, 97, 75)),
                    title: Text('Phone'),
                    subtitle: Text('09617586513'),
                  ),
                  ListTile(
                    leading: Icon(Icons.location_on, color: Color.fromARGB(255, 129, 97, 75)),
                    title: Text('Address'),
                    subtitle: Text('3371 Harvard St, Brgy. Pinagkaisahan, Makati City'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}