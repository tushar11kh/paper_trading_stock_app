// // lib/common/widgets/portfolio_section.dart

// import 'package:flutter/material.dart';
// import '../../../../../common/widgets/stock_card.dart';

// class PortfolioSection extends StatelessWidget {
//   const PortfolioSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Text("Most Traded Today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
//             const Spacer(),
//             TextButton(onPressed: () {}, child: const Text("View All"))
//           ],
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           height: 130,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             children: const [
//               StockCard(
//                 name: "APPL",
//                 company: "Apple Inc.",
//                 value: "\$131.46",
//                 change: "-2.02%",
//                 isPositive: false,
//               ),
//               SizedBox(width: 16),
//               StockCard(
//                 name: "LYFT",
//                 company: "Lyft Inc.",
//                 value: "\$326.42",
//                 change: "+3.12%",
//                 isPositive: true,
//               ),
//             ],
//           ),
//         )
//       ],
//     );
//   }
// }
