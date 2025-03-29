// Restaurants (10 entries, added isFavorite and deliveryTime)
List<Map<String, dynamic>> mockRestaurants = [
  {
    'id': 1,
    'name': 'Tasty Bites',
    'image': 'https://images.unsplash.com/photo-1512152272829-e39126e1295f?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'menu': {
      'Burger': {'price': 10, 'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
      'Fries': {'price': 3, 'image': 'https://images.unsplash.com/photo-1572802419224-296b0aeee0d9?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
    },
    'isFavorite': true,
    'deliveryTime': '20-30 min', // Added for delivery estimate
  },
  {
    'id': 2,
    'name': 'Pizza Haven',
    'image': 'https://images.unsplash.com/photo-1513106580091-1d82408b8cd6?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'menu': {
      'Pizza': {'price': 12, 'image': 'https://images.unsplash.com/photo-1571066815191-6b4e8d2365f0?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
      'Soda': {'price': 2, 'image': 'https://images.unsplash.com/photo-1624516854318-3e9e8b8e6b3b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
    },
    'isFavorite': false,
    'deliveryTime': '25-35 min',
  },
  {
    'id': 3,
    'name': 'Sushi Delight',
    'image': 'https://images.unsplash.com/photo-1579584425555-849d2b5d1c27?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'menu': {
      'Sushi Roll': {'price': 15, 'image': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
      'Miso Soup': {'price': 4, 'image': 'https://images.unsplash.com/photo-1617096700797-73dfa7b1fd56?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
    },
    'isFavorite': true,
    'deliveryTime': '30-40 min',
  },
  {
    'id': 4,
    'name': 'Curry Corner',
    'image': 'https://images.unsplash.com/photo-1606495735533-65c4e9988470?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'menu': {
      'Chicken Curry': {'price': 11, 'image': 'https://images.unsplash.com/photo-1604901383290-91e6b6d3d1a5?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
      'Naan': {'price': 3, 'image': 'https://images.unsplash.com/photo-1619537580898-0a03c0860e59?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
    },
    'isFavorite': false,
    'deliveryTime': '15-25 min',
  },
  {
    'id': 5,
    'name': 'Taco Fiesta',
    'image': 'https://images.unsplash.com/photo-1551504734-5ee1c4a14705?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'menu': {
      'Taco': {'price': 8, 'image': 'https://images.unsplash.com/photo-1551504734-83ee43e53514?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
      'Guacamole': {'price': 5, 'image': 'https://images.unsplash.com/photo-1603046899560-0bf2e4d6e06e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
    },
    'isFavorite': true,
    'deliveryTime': '20-30 min',
  },
  {
    'id': 6,
    'name': 'Pasta Palace',
    'image': 'https://images.unsplash.com/photo-1622973536968-3eadccb9cffc?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'menu': {
      'Spaghetti': {'price': 13, 'image': 'https://images.unsplash.com/photo-1608890270668-39fc4e359d34?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
      'Garlic Bread': {'price': 4, 'image': 'https://images.unsplash.com/photo-1598379230548-5f7fb47fe63b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
    },
    'isFavorite': false,
    'deliveryTime': '25-35 min',
  },
  {
    'id': 7,
    'name': 'BBQ Bliss',
    'image': 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'menu': {
      'Ribs': {'price': 18, 'image': 'https://images.unsplash.com/photo-1592853621830-1b3177c6185f?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
      'Coleslaw': {'price': 3, 'image': 'https://images.unsplash.com/photo-1622643049740-4f58e4e531d8?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
    },
    'isFavorite': false,
    'deliveryTime': '35-45 min',
  },
  {
    'id': 8,
    'name': 'Veggie Vibes',
    'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'menu': {
      'Salad': {'price': 9, 'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
      'Smoothie': {'price': 6, 'image': 'https://images.unsplash.com/photo-1505252585461-04db1eb84625?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
    },
    'isFavorite': true,
    'deliveryTime': '15-25 min',
  },
  {
    'id': 9,
    'name': 'Dim Sum Den',
    'image': 'https://images.unsplash.com/photo-1610647752706-3bb12232b2eb?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'menu': {
      'Dumplings': {'price': 10, 'image': 'https://images.unsplash.com/photo-1601333093326-42ca3e5a1495?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
      'Tea': {'price': 2, 'image': 'https://images.unsplash.com/photo-1578985545068-5849370a8e74?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
    },
    'isFavorite': false,
    'deliveryTime': '20-30 min',
  },
  {
    'id': 10,
    'name': 'Dessert Dream',
    'image': 'https://images.unsplash.com/photo-1551024601-bec78aea704b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'menu': {
      'Cake': {'price': 7, 'image': 'https://images.unsplash.com/photo-1578985545068-5849370a8e74?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
      'Ice Cream': {'price': 5, 'image': 'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'},
    },
    'isFavorite': true,
    'deliveryTime': '10-20 min',
  },
];

// Grocery Items (5 entries, added isFavorite and deliveryTime)
List<Map<String, dynamic>> mockGroceries = [
  {
    'id': 1,
    'name': 'Fresh Apples',
    'price': 2.5,
    'image': 'https://images.unsplash.com/photo-1567306226416-28f0ef73a540?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'isFavorite': true,
    'deliveryTime': '15-25 min', // Added for delivery estimate
  },
  {
    'id': 2,
    'name': 'Organic Milk',
    'price': 3.0,
    'image': 'https://images.unsplash.com/photo-1603533792099-32d5c58f55fe?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'isFavorite': false,
    'deliveryTime': '20-30 min',
  },
  {
    'id': 3,
    'name': 'Whole Bread',
    'price': 2.0,
    'image': 'https://images.unsplash.com/photo-1598373182133-5243682d7014?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'isFavorite': true,
    'deliveryTime': '15-25 min',
  },
  {
    'id': 4,
    'name': 'Eggs (Dozen)',
    'price': 4.0,
    'image': 'https://images.unsplash.com/photo-1584269602048-0e2f4c98e444?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'isFavorite': false,
    'deliveryTime': '20-30 min',
  },
  {
    'id': 5,
    'name': 'Avocado',
    'price': 1.5,
    'image': 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
    'isFavorite': true,
    'deliveryTime': '10-20 min',
  },
];

// Discover Items (3 entries, unchanged but verified for Community Favorite)
List<Map<String, dynamic>> mockDiscover = [
  {
    'id': 1,
    'title': 'Pizza Party Deal',
    'description': '2 Pizzas + Soda for \$20',
    'image': 'https://images.unsplash.com/photo-1595854341625-fc9e6a9a7d2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
  },
  {
    'id': 2,
    'title': 'Sushi Night',
    'description': '20% off all sushi rolls',
    'image': 'https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
  },
  {
    'id': 3,
    'title': 'Taco Tuesday',
    'description': 'Buy 2 Tacos, Get 1 Free',
    'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
  },
];