import unittest
from pilot_session import select_pair

class PilotSessionTest(unittest.TestCase):
    def test_only_new_unique_pair(self):
        self.assertEqual(('scaled_doc.jpg', 'CAP123.jpg'), select_pair({'scaled_doc.jpg','CAP123.jpg','unrelated.txt'}))

    def test_retakes_require_explicit_selection(self):
        names={'scaled_doc.jpg','CAP123.jpg','CAP456.jpg'}
        with self.assertRaises(ValueError): select_pair(names)
        self.assertEqual(('scaled_doc.jpg','CAP456.jpg'), select_pair(names,live='CAP456.jpg'))

    def test_cannot_select_previous_session(self):
        with self.assertRaises(ValueError): select_pair({'scaled_doc.jpg','CAP123.jpg'},live='CAPold.jpg')

    def test_path_traversal_and_missing_capture_rejected(self):
        with self.assertRaises(ValueError): select_pair({'scaled_../../doc.jpg','CAP123.jpg'})
        with self.assertRaises(ValueError): select_pair({'scaled_doc.jpg'})
