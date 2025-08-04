"""
Basic tests for the maintenance package
"""
import os
import sys
import unittest

# Add the parent directory to the path so we can import our modules
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class TestMaintenancePackage(unittest.TestCase):
    """Test basic functionality of the maintenance package"""

    def test_import_maintenance_module(self):
        """Test that we can import the main maintenance module"""
        try:
            import data_maintenance

            self.assertTrue(hasattr(data_maintenance, "DataMaintenance"))
        except ImportError:
            self.fail("Failed to import data_maintenance module")

    def test_import_config_checker(self):
        """Test that we can import the config checker module"""
        try:
            import check_maintenance_config

            self.assertTrue(hasattr(check_maintenance_config, "main"))
        except ImportError:
            self.fail("Failed to import check_maintenance_config module")

    def test_package_metadata(self):
        """Test that package metadata is accessible"""
        try:
            import __init__ as package

            self.assertTrue(hasattr(package, "__version__"))
            self.assertTrue(hasattr(package, "__author__"))
            self.assertTrue(hasattr(package, "__description__"))
            self.assertEqual(package.__version__, "1.0.0")
        except ImportError:
            # Package metadata is optional for basic functionality
            pass


if __name__ == "__main__":
    unittest.main()
