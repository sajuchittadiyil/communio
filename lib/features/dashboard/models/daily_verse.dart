class DailyVerse {
  const DailyVerse(this.text, this.reference);

  final String text;
  final String reference;
}

class DailyVerseCalendar {
  DailyVerseCalendar._();

  static const verses = <DailyVerse>[
    DailyVerse(
      'Let all your things be done with charity.',
      '1 Corinthians 16:14',
    ),
    DailyVerse('We walk by faith, not by sight.', '2 Corinthians 5:7'),
    DailyVerse(
      'Rejoicing in hope; patient in tribulation; continuing instant in prayer.',
      'Romans 12:12',
    ),
    DailyVerse(
      'Be kindly affectioned one to another with brotherly love.',
      'Romans 12:10',
    ),
    DailyVerse('With God all things are possible.', 'Matthew 19:26'),
    DailyVerse('Blessed are the peacemakers.', 'Matthew 5:9'),
    DailyVerse('Ye are the light of the world.', 'Matthew 5:14'),
    DailyVerse('Freely ye have received, freely give.', 'Matthew 10:8'),
    DailyVerse(
      'For where your treasure is, there will your heart be also.',
      'Matthew 6:21',
    ),
    DailyVerse(
      'Ask, and it shall be given you; seek, and ye shall find.',
      'Matthew 7:7',
    ),
    DailyVerse('Love one another; as I have loved you.', 'John 13:34'),
    DailyVerse(
      'Let not your heart be troubled: ye believe in God.',
      'John 14:1',
    ),
    DailyVerse('Abide in me, and I in you.', 'John 15:4'),
    DailyVerse(
      'Greater love hath no man than this, that a man lay down his life for his friends.',
      'John 15:13',
    ),
    DailyVerse('Be of good cheer; I have overcome the world.', 'John 16:33'),
    DailyVerse('The Lord is my shepherd; I shall not want.', 'Psalm 23:1'),
    DailyVerse('Create in me a clean heart, O God.', 'Psalm 51:10'),
    DailyVerse('Be still, and know that I am God.', 'Psalm 46:10'),
    DailyVerse(
      'Thy word is a lamp unto my feet, and a light unto my path.',
      'Psalm 119:105',
    ),
    DailyVerse(
      'This is the day which the Lord hath made; we will rejoice and be glad in it.',
      'Psalm 118:24',
    ),
    DailyVerse('Trust in the Lord with all thine heart.', 'Proverbs 3:5'),
    DailyVerse('A soft answer turneth away wrath.', 'Proverbs 15:1'),
    DailyVerse(
      'Iron sharpeneth iron; so a man sharpeneth the countenance of his friend.',
      'Proverbs 27:17',
    ),
    DailyVerse('To every thing there is a season.', 'Ecclesiastes 3:1'),
    DailyVerse(
      'They that wait upon the Lord shall renew their strength.',
      'Isaiah 40:31',
    ),
    DailyVerse('Fear thou not; for I am with thee.', 'Isaiah 41:10'),
    DailyVerse('Here am I; send me.', 'Isaiah 6:8'),
    DailyVerse('The joy of the Lord is your strength.', 'Nehemiah 8:10'),
    DailyVerse('Be strong and of a good courage.', 'Joshua 1:9'),
    DailyVerse(
      'Do justly, and to love mercy, and to walk humbly with thy God.',
      'Micah 6:8',
    ),
    DailyVerse('Bear ye one another’s burdens.', 'Galatians 6:2'),
    DailyVerse(
      'The fruit of the Spirit is love, joy, peace, longsuffering, gentleness, goodness, faith.',
      'Galatians 5:22',
    ),
    DailyVerse(
      'I can do all things through Christ which strengtheneth me.',
      'Philippians 4:13',
    ),
    DailyVerse('Let your moderation be known unto all men.', 'Philippians 4:5'),
    DailyVerse('Pray without ceasing.', '1 Thessalonians 5:17'),
    DailyVerse(
      'God hath not given us the spirit of fear; but of power, and of love.',
      '2 Timothy 1:7',
    ),
  ];

  static DailyVerse forDate(DateTime date) {
    final day = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(1970)).inDays;
    return verses[day % verses.length];
  }
}
