class GetAdjustedDate {
  execute(DateTime date) {
    int dayOfWeek = date.weekday; // Lundi est 1, Dimanche est 7

    // Si c'est dimanche, retournez la date actuelle, sinon soustrayez le nombre de jours
    return (dayOfWeek == 7) ? date : date.subtract(Duration(days: dayOfWeek));
  }
}