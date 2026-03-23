export const en = {
	app: {
		title: 'Hex',
		boardSize: 'Board {size}x{size}',
		emptyState: 'Start a new game to play',
		language: 'Language'
	},
	mode: {
		humanVsAi: 'Play vs AI',
		humanVsHuman: 'Two players',
		aiVsAi: 'AI vs AI'
	},
	colors: {
		blue: 'Blue',
		red: 'Red'
	},
	help: {
		learnMore: 'Learn about Hex on Wikipedia'
	},
	goal: {
		top: 'top',
		bottom: 'bottom',
		left: 'left',
		right: 'right'
	},
	status: {
		youWin: 'You win',
		aiWins: 'AI wins',
		blueWins: 'Blue wins',
		redWins: 'Red wins',
		gameFinished: 'Game finished',
		aiThinking: 'AI is thinking',
		blueThinking: 'Blue is choosing a move',
		redThinking: 'Red is choosing a move',
		yourTurn: 'Your turn',
		aiTurn: 'AI turn',
		blueTurn: 'Blue to move',
		redTurn: 'Red to move',
		blueConnected: 'Blue connected top to bottom.',
		redConnected: 'Red connected left to right.',
		chooseCell: 'Choose any open cell on the board.',
		waitForAi: 'Please wait for the AI move.',
		aiChoosing: 'The AI is choosing its next move.'
	},
	sidebar: {
		youArePlaying: 'You are playing',
		mode: 'Mode',
		depth: 'Depth',
		blueRule: 'Blue moves first and wins by connecting the top edge to the bottom edge.',
		redRule: 'Red moves second and wins by connecting the left edge to the right edge.',
		aiVsAiRule: 'Both sides are controlled by AI using the selected search depth.',
		controls: 'Controls',
		autoPlay: 'Auto play',
		pause: 'Pause',
		nextMove: 'Next move',
		newGame: 'New Game'
	},
	moves: {
		title: 'Moves',
		empty: 'No moves yet',
		you: 'You',
		ai: 'AI'
	},
	dialog: {
		newGame: 'New Game',
		gameMode: 'Game mode',
		boardSize: 'Board size',
		playAs: 'Play as',
		blueHint: '1st move',
		redHint: '2nd move',
		humanSides: 'Sides in two-player mode',
		aiSides: 'Sides in AI vs AI',
		aiDepth: 'AI depth (half-moves)',
		recommendedDepth: 'Recommended for {size}x{size}: {depth}',
		start: 'Start'
	},
	errors: {
		backendUnavailable: 'The backend is not responding. Please try again.',
		failedCreateGame: 'Failed to create game',
		invalidMove: 'Invalid move',
		failedAiMove: 'Failed to make AI move'
	},
	accessibility: {
		cell: 'Cell {row},{col}',
		goalVertical: 'Connect top to bottom',
		goalHorizontal: 'Connect left to right',
		languageEnglish: 'Switch to English',
		languageUkrainian: 'Switch to Ukrainian'
	}
} as const;

export const uk = {
	app: {
		title: 'Hex',
		boardSize: 'Поле {size}x{size}',
		emptyState: 'Почніть нову гру, щоб зіграти',
		language: 'Мова'
	},
	mode: {
		humanVsAi: 'Грати проти ШІ',
		humanVsHuman: 'Двоє гравців',
		aiVsAi: 'ШІ проти ШІ'
	},
	colors: {
		blue: 'Синій',
		red: 'Червоний'
	},
	help: {
		learnMore: 'Дізнатися більше про Hex у Вікіпедії'
	},
	goal: {
		top: 'верх',
		bottom: 'низ',
		left: 'ліво',
		right: 'право'
	},
	status: {
		youWin: 'Ви перемогли',
		aiWins: 'ШІ переміг',
		blueWins: 'Синій переміг',
		redWins: 'Червоний переміг',
		gameFinished: 'Гру завершено',
		aiThinking: 'ШІ думає',
		blueThinking: 'Синій обирає хід',
		redThinking: 'Червоний обирає хід',
		yourTurn: 'Ваш хід',
		aiTurn: 'Хід ШІ',
		blueTurn: 'Хід синього',
		redTurn: 'Хід червоного',
		blueConnected: 'Синій зʼєднав верх і низ.',
		redConnected: 'Червоний зʼєднав лівий і правий бік.',
		chooseCell: 'Оберіть будь-яку вільну клітинку на полі.',
		waitForAi: 'Зачекайте, поки ШІ зробить хід.',
		aiChoosing: 'ШІ обирає свій наступний хід.'
	},
	sidebar: {
		youArePlaying: 'Ви граєте за',
		mode: 'Режим',
		depth: 'Глибина',
		blueRule: 'Синій ходить першим і перемагає, якщо зʼєднає верхній і нижній краї.',
		redRule: 'Червоний ходить другим і перемагає, якщо зʼєднає лівий і правий краї.',
		aiVsAiRule: 'Обидві сторони контролює ШІ з обраною глибиною пошуку.',
		controls: 'Керування',
		autoPlay: 'Автогра',
		pause: 'Пауза',
		nextMove: 'Наступний хід',
		newGame: 'Нова гра'
	},
	moves: {
		title: 'Ходи',
		empty: 'Ходів ще немає',
		you: 'Ви',
		ai: 'ШІ'
	},
	dialog: {
		newGame: 'Нова гра',
		gameMode: 'Режим гри',
		boardSize: 'Розмір поля',
		playAs: 'Грати за',
		blueHint: 'Ходить першим',
		redHint: 'Ходить другим',
		humanSides: 'Сторони у режимі для двох гравців',
		aiSides: 'Сторони у режимі ШІ проти ШІ',
		aiDepth: 'Глибина ШІ (півходів)',
		recommendedDepth: 'Рекомендовано для {size}x{size}: {depth}',
		start: 'Почати'
	},
	errors: {
		backendUnavailable: 'Бекенд не відповідає. Спробуйте ще раз.',
		failedCreateGame: 'Не вдалося створити гру',
		invalidMove: 'Некоректний хід',
		failedAiMove: 'Не вдалося зробити хід ШІ'
	},
	accessibility: {
		cell: 'Клітинка {row},{col}',
		goalVertical: 'Зʼєднати верх і низ',
		goalHorizontal: 'Зʼєднати лівий і правий бік',
		languageEnglish: 'Перемкнути на англійську',
		languageUkrainian: 'Перемкнути на українську'
	}
} as const;
