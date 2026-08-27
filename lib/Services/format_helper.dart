class FormatHelper {
  static String formatCurrency(dynamic value) {
    if (value == null) return "0";
    double? amount;
    if (value is String) {
      amount = double.tryParse(value);
    } else if (value is num) {
      amount = value.toDouble();
    }
    
    if (amount == null) return value.toString();

    if (amount >= 10000000) {
      return "${(amount / 10000000).toStringAsFixed(amount % 10000000 == 0 ? 0 : 1)} CR";
    } else if (amount >= 100000) {
      return "${(amount / 100000).toStringAsFixed(amount % 100000 == 0 ? 0 : 1)} L";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)} K";
    } else {
      return amount.toInt().toString();
    }
  }

  static String getFeesRange(Map<String, dynamic>? feesChart, {String? period}) {
    if (feesChart == null || feesChart.isEmpty) return "";

    List<double> values = [];
    for (var val in feesChart.values) {
      double? d = double.tryParse(val.toString());
      if (d != null) values.add(d);
    }

    if (values.isEmpty) return "";

    double min = values.reduce((a, b) => a < b ? a : b);
    double max = values.reduce((a, b) => a > b ? a : b);

    String suffix = "";
    if (period != null) {
      switch (period.toLowerCase()) {
        case "monthly": suffix = " /mo"; break;
        case "yearly": suffix = " /yr"; break;
        case "hourly": suffix = " /hr"; break;
        case "per session": suffix = " /session"; break;
        case "one-time": suffix = " once"; break;
      }
    }

    if (min == max) {
      return "₹ ${formatCurrency(min)}$suffix";
    } else {
      return "₹ ${formatCurrency(min)} - ${formatCurrency(max)}$suffix";
    }
  }
}
